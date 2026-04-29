import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.22.0";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") || "AIzaSyBlOIuJNwvkfzaYCseAbhMuF5ubEg6YiFA";
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") || "gemma-4-26b-a4b-it";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

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

    const { data: history } = await supabase
      .from("ai_messages")
      .select("role, content")
      .eq("conversation_id", conversationId)
      .eq("status", "complete")
      .neq("id", userMessageId) // Exclude current message so it's not double-fed
      .order("created_at", { ascending: true })
      .limit(10);

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

    const chat = model.startChat({
      history: (history || []).map((m: any) => ({
        role: m.role === "user" ? "user" : "model",
        parts: [{ text: m.content }],
      })),
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
      // 1. Remove thought tags
      let cleanText = chunkText.replace(/<thought>[\s\S]*?<\/thought>/gi, "").replace(/<thought>[\s\S]*$/gi, "");
      
      // 2. Clean up malformed bolding with spaces (common in MoE output)
      // Fixes "** text **" -> "**text**" for correct Markdown parsing
      cleanText = cleanText.replace(/\*\*\s+(.*?)\s+\*\*/g, "**$1**");

      if (cleanText) {
        fullText += cleanText;
        await supabase.from("ai_messages").update({
          content: fullText,
          updated_at: new Date().toISOString(),
        }).eq("id", assistantMessageId);
      }
    }

    await supabase.from("ai_messages").update({
      content: sanitizeAssistantResponse(fullText, userMsg.content),
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

function sanitizeAssistantResponse(raw: string, userPrompt: string) {
  let cleaned = raw
    .replace(/<thought>[\s\S]*?<\/thought>/gi, "")
    .replace(/<thought>[\s\S]*$/gi, "")
    .replace(/\*\*\s+(.*?)\s+\*\*/g, "**$1**")
    .trim();

  const prompt = userPrompt.trim();
  if (!prompt || !cleaned) return cleaned;

  const escapedPrompt = prompt.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const leadingEchoPatterns = [
    new RegExp(`^(user\\s*:?\\s*)?${escapedPrompt}\\s*[-:]*\\s*`, "i"),
    new RegExp(`^["']${escapedPrompt}["']\\s*[-:]*\\s*`, "i"),
  ];

  for (const pattern of leadingEchoPatterns) {
    cleaned = cleaned.replace(pattern, "").trim();
  }

  return cleaned || "I'm sorry, I could not generate a useful response. Please try rephrasing your question.";
}
