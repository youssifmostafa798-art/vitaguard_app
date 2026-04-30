// @ts-nocheck – Deno runtime globals
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.22.0";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") || "gemma-4-26b-a4b-it";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const SAFE_FALLBACK_RESPONSE =
  "I'm sorry, I could not generate a useful response. Please try rephrasing your question.";

class HttpError extends Error {
  constructor(public status: number, message: string, public details?: string) {
    super(message);
    this.name = "HttpError";
  }
}

async function jsonResponse(data: any, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    },
  });
}

async function getUserIdFromRequest(req: Request) {
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader) throw new HttpError(401, "Missing Authorization.");
  
  const token = authHeader.replace(/^[Bb]earer\s+/, "");
  const supabaseAuthClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const { data, error } = await supabaseAuthClient.auth.getUser(token);
  
  if (error || !data.user) throw new HttpError(401, "Invalid session.");
  return data.user.id;
}

function requireUuid(value: unknown, field: string) {
  if (typeof value !== "string" || !value.trim()) {
    throw new HttpError(400, "Invalid input", `Missing required field: ${field}.`);
  }

  const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  if (!uuidPattern.test(value)) {
    throw new HttpError(400, "Invalid input", `${field} must be a valid UUID.`);
  }

  return value;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return jsonResponse("ok");

  try {
    const userId = await getUserIdFromRequest(req);
    const body = (await req.json()) as any;
    const conversationId = requireUuid(body?.conversationId, "conversationId");
    const userMessageId = requireUuid(body?.userMessageId, "userMessageId");

    if (!GEMINI_API_KEY) {
      throw new HttpError(500, "AI assistant is not configured.", "Missing GEMINI_API_KEY.");
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const assistantMessageId = crypto.randomUUID();
    const now = new Date().toISOString();

    await supabase.from("ai_messages").insert({
      id: assistantMessageId,
      conversation_id: conversationId,
      owner_user_id: userId,
      role: "assistant",
      content: "",
      status: "streaming",
      created_at: now,
      updated_at: now,
    });

    (EdgeRuntime as any).waitUntil(processRequest(supabase, conversationId, assistantMessageId, userMessageId));

    return jsonResponse({ assistantMessageId, status: "streaming" }, 202);

  } catch (error) {
    const status = error instanceof HttpError ? error.status : 500;
    return jsonResponse({
      error: error instanceof Error ? error.message : "Internal Error",
      details: error instanceof HttpError ? error.details : undefined,
    }, status);
  }
});

async function processRequest(supabase: any, conversationId: string, assistantMessageId: string, userMessageId: string) {
  try {
    const { data: userMsg, error: userMessageError } = await supabase
      .from("ai_messages")
      .select("content, role, conversation_id")
      .eq("id", userMessageId)
      .eq("conversation_id", conversationId)
      .single();

    if (userMessageError || !userMsg) throw new Error("User message not found.");
    if (userMsg.role !== "user") throw new Error("Message must be a user prompt.");

    const { data: rawHistory } = await supabase
      .from("ai_messages")
      .select("role, content")
      .eq("conversation_id", conversationId)
      .eq("status", "complete")
      .neq("id", userMessageId) // Exclude current message so it's not double-fed
      .neq("id", assistantMessageId) // Exclude the streaming placeholder too
      .neq("role", "system")
      .order("created_at", { ascending: false })
      .limit(10);

    const history = (rawHistory || []).reverse();

    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
    const model = genAI.getGenerativeModel({ 
      model: GEMINI_MODEL,
      systemInstruction: `You are a clinical AI assistant for VitaGuard.
STRICT FORMATTING RULES:
1. USE STANDARD MARKDOWN ONLY.
2. For bolding, use **text** WITHOUT internal spaces (e.g., do NOT use ** text **).
3. Use * for bullet points (e.g., * Item).
4. Hide all your internal thinking or tags (<thought>).
5. Never show technical debugging info.
6. Provide expert healthcare answers and wellness tips.
7. NEVER repeat, paraphrase, or echo the user's input. Respond concisely with only new, relevant information.`,
    });

    const formattedHistory: any[] = [];
    let lastRole: string | null = null;
    for (const msg of history) {
      const currentRole = msg.role === "user" ? "user" : "model";
      if (currentRole !== lastRole) {
        formattedHistory.push({
          role: currentRole,
          parts: [{ text: msg.content }],
        });
        lastRole = currentRole;
      } else {
        formattedHistory[formattedHistory.length - 1].parts[0].text += `\n\n${msg.content}`;
      }
    }

    const chat = model.startChat({
      history: formattedHistory,
      generationConfig: {
        maxOutputTokens: 2000,
        temperature: 0.7,
      },
    });

    const result = await chat.sendMessageStream(userMsg.content);
    let fullText = "";

    for await (const chunk of result.stream) {
      if (!chunk.text) continue;
      
      const chunkText = chunk.text();
      if (chunkText) {
        fullText += chunkText;
        const sanitizedPartial = sanitizeAssistantResponse(fullText, userMsg.content, {
          fallbackWhenEmpty: false,
        });
        if (!sanitizedPartial) continue;

        await supabase.from("ai_messages").update({
          content: sanitizedPartial,
          updated_at: new Date().toISOString(),
        }).eq("id", assistantMessageId);
      }
    }

    const finalText = sanitizeAssistantResponse(fullText, userMsg.content, {
      fallbackWhenEmpty: true,
    });

    await supabase.from("ai_messages").update({
      content: isUnsafeAssistantResponse(finalText, userMsg.content)
        ? SAFE_FALLBACK_RESPONSE
        : finalText,
      status: "complete",
      updated_at: new Date().toISOString(),
    }).eq("id", assistantMessageId);

  } catch (error) {
    await supabase.from("ai_messages").update({
      content: "I'm sorry, I'm having trouble thinking right now. Please try again soon.",
      status: "error",
      error_message: error instanceof Error ? error.message : "Generation failed",
      updated_at: new Date().toISOString(),
    }).eq("id", assistantMessageId);
  }
}

function sanitizeAssistantResponse(
  raw: string,
  userPrompt: string,
  options: { fallbackWhenEmpty: boolean } = { fallbackWhenEmpty: true },
) {
  let cleaned = raw
    .replace(/<thought>[\s\S]*?<\/thought>/gi, "")
    .replace(/<thought>[\s\S]*$/gi, "")
    .replace(/\*\*\s+(.*?)\s+\*\*/g, "**$1**")
    .trim();

  cleaned = cleaned
    .split("\n")
    .filter((line) => !isBlockedInstructionLine(line))
    .join("\n")
    .trim();

  const prompt = userPrompt.trim();
  if (!prompt || !cleaned) {
    return cleaned || (options.fallbackWhenEmpty ? SAFE_FALLBACK_RESPONSE : "");
  }

  const escapedPrompt = prompt.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  
  // Remove user prefix patterns globally just in case model hallucinated it
  const userPrefixPattern = new RegExp(`(?:user|patient)\\s*:?\\s*${escapedPrompt}`, "gi");
  cleaned = cleaned.replace(userPrefixPattern, "").trim();

  const repeatedPrompt = new RegExp(`^(?:${escapedPrompt}){2,}\\s*`, "i");
  cleaned = cleaned.replace(repeatedPrompt, "").trimStart();

  const leadingEchoPatterns = [
    new RegExp(`^(user\\s*:?\\s*)?${escapedPrompt}(?:\\s+|\\s*[-:]\\s+)`, "i"),
    new RegExp(`^["']${escapedPrompt}["']\\s*[-:]*\\s*`, "i"),
    new RegExp(`^${escapedPrompt}\\s*`, "i"),
  ];

  let changed = true;
  while (changed && cleaned) {
    changed = false;
    for (const pattern of leadingEchoPatterns) {
      const next = cleaned.replace(pattern, "").trimStart();
      if (next !== cleaned) {
        cleaned = next;
        changed = true;
      }
    }
  }

  return cleaned || (options.fallbackWhenEmpty ? SAFE_FALLBACK_RESPONSE : "");
}

function isBlockedInstructionLine(line: string) {
  return /^\s*(Goal|Tone|Formatting)\s*:/i.test(line) ||
    /^\s*STRICT\s+FORMATTING\s+RULES\s*:?/i.test(line) ||
    /^\s*You are a clinical AI assistant/i.test(line);
}

function isUnsafeAssistantResponse(response: string, userPrompt: string) {
  if (response.split("\n").some(isBlockedInstructionLine)) return true;

  const prompt = normalizeForLeakCheck(userPrompt);
  const content = normalizeForLeakCheck(response);
  if (prompt.length < 12) return false;

  return content.includes(prompt);
}

function normalizeForLeakCheck(value: string) {
  return value.toLowerCase().replace(/\s+/g, " ").trim();
}
