import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.22.0";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") || "AIzaSyBlOIuJNwvkfzaYCseAbhMuF5ubEg6YiFA";
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") || "gemma-4-26b-a4b-it";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

class HttpError extends Error {
  constructor(public status: number, message: string) {
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

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return jsonResponse("ok");

  try {
    const userId = await getUserIdFromRequest(req);
    const body = (await req.json()) as any;
    const { conversationId, userMessageId } = body;

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
    return jsonResponse({ error: error instanceof Error ? error.message : "Internal Error" }, status);
  }
});

async function processRequest(supabase: any, conversationId: string, assistantMessageId: string, userMessageId: string) {
  try {
    const { data: userMsg } = await supabase.from("ai_messages").select("content").eq("id", userMessageId).single();
    if (!userMsg) throw new Error("User message not found.");

    const { data: history } = await supabase
      .from("ai_messages")
      .select("role, content")
      .eq("conversation_id", conversationId)
      .eq("status", "complete")
      .order("created_at", { ascending: true })
      .limit(10);

    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
    const model = genAI.getGenerativeModel({ 
      model: GEMINI_MODEL,
      systemInstruction: `You are VitaGuard AI.
STRICT FORMATTING RULES:
1. USE STANDARD MARKDOWN ONLY.
2. For bolding, use **text** WITHOUT internal spaces (e.g., do NOT use ** text **).
3. Use * for bullet points (e.g., * Item).
4. Hide all your internal thinking or tags (<thought>).
5. Never show technical debugging info.
6. Provide expert healthcare answers and wellness tips.`,
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
      content: fullText.trim(),
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
