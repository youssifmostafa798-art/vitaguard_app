import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.22.0";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") || "AIzaSyBlOIuJNwvkfzaYCseAbhMuF5ubEg6YiFA";
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") || "gemma-4-26b-a4b-it";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SB_PUBLISHABLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY") ?? "";

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
    },
  });
}

async function getUserIdFromRequest(req: Request) {
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader) throw new HttpError(401, "Missing Authorization.");
  
  const token = authHeader.replace(/^[Bb]earer\s+/, "");
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  const { data, error } = await supabase.auth.getUser(token);
  
  if (error || !data.user) throw new HttpError(401, "Invalid session.");
  return data.user.id;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const userId = await getUserIdFromRequest(req);
    const body = await req.json();
    const { conversationId, userMessageId } = (body as any);

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
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
      .order("created_at", { ascending: true });

    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
    const model = genAI.getGenerativeModel({ model: GEMINI_MODEL });

    const chat = model.startChat({
      history: (history || []).map((m: any) => ({
        role: m.role === "user" ? "user" : "model",
        parts: [{ text: m.content }],
      })),
    });

    const result = await chat.sendMessageStream(userMsg.content);
    let fullText = "";

    for await (const chunk of result.stream) {
      const chunkText = chunk.text();
      fullText += chunkText;
      
      await supabase.from("ai_messages").update({
        content: fullText,
        updated_at: new Date().toISOString(),
      }).eq("id", assistantMessageId);
    }

    await supabase.from("ai_messages").update({
      content: fullText,
      status: "complete",
      updated_at: new Date().toISOString(),
    }).eq("id", assistantMessageId);

  } catch (error) {
    console.error("SDK Error:", error);
    await supabase.from("ai_messages").update({
      content: "I'm sorry, I'm having trouble connecting to the AI service. Please check your model settings or try again in a moment.",
      status: "error",
      error_message: error instanceof Error ? error.message : "Unknown SDK Error",
      updated_at: new Date().toISOString(),
    }).eq("id", assistantMessageId);
  }
}
