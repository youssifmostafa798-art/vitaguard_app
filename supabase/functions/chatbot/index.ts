import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import { getUserIdFromRequest } from "../_shared/auth.ts";
import { corsHeaders } from "../_shared/cors.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "AIzaSyBlOIuJNwvkfzaYCseAbhMuF5ubEg6YiFA";
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemma-4-26b-it";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_PUBLIC_KEY =
  Deno.env.get("SUPABASE_ANON_KEY") ??
  Deno.env.get("SB_PUBLISHABLE_KEY") ??
  "";

const MAX_INPUT_CHARS = 2000;
const HISTORY_LIMIT = 12;
const MAX_PROMPTS_PER_HOUR = 20;
const STREAM_FLUSH_MS = 650;
const STREAM_FLUSH_CHARS = 160;
const SAFE_ERROR_REPLY =
  "I'm sorry, but I couldn't finish that reply right now. Please try again in a moment.";

type ConversationRole = "patient" | "companion" | "doctor";
type MessageRole = "user" | "assistant" | "system";

type ConversationRow = {
  id: string;
  owner_user_id: string;
  role: ConversationRole;
  context_patient_id: string | null;
  title: string | null;
};

type MessageRow = {
  id: string;
  role: MessageRole;
  content: string;
  status: "streaming" | "complete" | "error";
  created_at: string;
};

type ProfileRow = {
  id: string;
  role: string;
  name: string | null;
  email: string | null;
  phone: string | null;
};

class HttpError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  try {
    if (!GEMINI_API_KEY) {
      throw new HttpError(500, "GEMINI_API_KEY is not configured.");
    }

    if (!SUPABASE_URL || !SUPABASE_PUBLIC_KEY) {
      throw new HttpError(
        500,
        "Supabase Edge Function environment is incomplete.",
      );
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    console.log(`[Chatbot] Incoming request. AuthHeader present: ${!!authHeader}`);

    if (!authHeader) {
      throw new HttpError(401, "Missing Authorization header.");
    }

    const userId = await getUserIdFromRequest(req);
    console.log(`[Chatbot] Authenticated user: ${userId}`);

    const body = await req.json();
    const conversationId = String(body?.conversationId ?? "").trim();
    const userMessageId = String(body?.userMessageId ?? "").trim();

    if (!conversationId || !userMessageId) {
      throw new HttpError(
        400,
        "conversationId and userMessageId are required.",
      );
    }

    const userClient = createUserClient(authHeader);
    const conversation = await loadConversation(
      userClient,
      conversationId,
      userId,
    );
    const userMessage = await loadUserMessage(
      userClient,
      userMessageId,
      conversationId,
      userId,
    );

    const prompt = userMessage.content.trim();
    if (!prompt) {
      throw new HttpError(400, "The message cannot be empty.");
    }
    if (prompt.length > MAX_INPUT_CHARS) {
      throw new HttpError(
        400,
        `Messages must be ${MAX_INPUT_CHARS} characters or fewer.`,
      );
    }

    await enforceRateLimit(userClient, userId);

    const assistantMessageId = crypto.randomUUID();
    const now = new Date().toISOString();

    const { error: insertError } = await userClient.from("ai_messages").insert({
      id: assistantMessageId,
      conversation_id: conversationId,
      owner_user_id: userId,
      role: "assistant",
      content: "",
      status: "streaming",
      provider: "gemini",
      model: GEMINI_MODEL,
      created_at: now,
      updated_at: now,
    });

    if (insertError) {
      throw insertError;
    }

    EdgeRuntime.waitUntil(
      processAssistantReply({
        authHeader,
        assistantMessageId,
        conversation,
        userId,
      }),
    );

    return jsonResponse(
      {
        assistantMessageId,
        status: "streaming",
      },
      202,
    );
  } catch (error) {
    const status = error instanceof HttpError ? error.status : 500;
    const message = error instanceof Error
      ? error.message
      : "Unexpected chatbot error.";

    return jsonResponse({ error: message }, status);
  }
});

async function processAssistantReply(args: {
  authHeader: string;
  assistantMessageId: string;
  conversation: ConversationRow;
  userId: string;
}) {
  const userClient = createUserClient(args.authHeader);
  let generated = "";
  let lastSaved = "";
  let lastFlushAt = 0;

  try {
    const history = await loadMessageHistory(userClient, args.conversation.id);
    const systemPrompt = await buildSystemPrompt(
      userClient,
      args.conversation,
      args.userId,
    );

    for await (const chunk of streamGeminiText({ systemPrompt, history })) {
      generated += chunk;

      const shouldFlush =
        generated.length - lastSaved.length >= STREAM_FLUSH_CHARS ||
        Date.now() - lastFlushAt >= STREAM_FLUSH_MS;

      if (!shouldFlush) continue;

      await updateAssistantMessage(userClient, args.assistantMessageId, {
        content: generated,
        status: "streaming",
      });
      lastSaved = generated;
      lastFlushAt = Date.now();
    }

    const finalReply = generated.trim() || SAFE_ERROR_REPLY;

    await finalizeConversation(userClient, args.conversation.id, finalReply);
    await updateAssistantMessage(userClient, args.assistantMessageId, {
      content: finalReply,
      status: generated.trim() ? "complete" : "error",
      error_message: generated.trim()
        ? null
        : "The model returned an empty reply.",
    });
  } catch (error) {
    const message = error instanceof Error
      ? error.message
      : "Chatbot generation failed.";

    await finalizeConversation(userClient, args.conversation.id, SAFE_ERROR_REPLY);
    await updateAssistantMessage(userClient, args.assistantMessageId, {
      content: SAFE_ERROR_REPLY,
      status: "error",
      error_message: message.slice(0, 300),
    });
  }
}

function createUserClient(authHeader: string) {
  return createClient(SUPABASE_URL, SUPABASE_PUBLIC_KEY, {
    auth: {
      persistSession: false,
    },
    global: {
      headers: {
        Authorization: authHeader,
      },
    },
  });
}

async function loadConversation(
  client: ReturnType<typeof createUserClient>,
  conversationId: string,
  userId: string,
) {
  const { data, error } = await client
    .from("ai_conversations")
    .select("id, owner_user_id, role, context_patient_id, title")
    .eq("id", conversationId)
    .eq("owner_user_id", userId)
    .limit(1);

  if (error) throw error;
  if (!data || data.length === 0) {
    throw new HttpError(404, "AI conversation not found.");
  }

  return data[0] as ConversationRow;
}

async function loadUserMessage(
  client: ReturnType<typeof createUserClient>,
  userMessageId: string,
  conversationId: string,
  userId: string,
) {
  const { data, error } = await client
    .from("ai_messages")
    .select("id, role, content, status, created_at")
    .eq("id", userMessageId)
    .eq("conversation_id", conversationId)
    .eq("owner_user_id", userId)
    .limit(1);

  if (error) throw error;
  if (!data || data.length === 0) {
    throw new HttpError(404, "User message not found.");
  }

  const row = data[0] as MessageRow;
  if (row.role !== "user") {
    throw new HttpError(400, "The referenced message must belong to the user.");
  }

  return row;
}

async function enforceRateLimit(
  client: ReturnType<typeof createUserClient>,
  userId: string,
) {
  const cutoff = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const { count, error } = await client
    .from("ai_messages")
    .select("id", { count: "exact", head: true })
    .eq("owner_user_id", userId)
    .eq("role", "user")
    .gte("created_at", cutoff);

  if (error) throw error;
  if ((count ?? 0) > MAX_PROMPTS_PER_HOUR) {
    throw new HttpError(
      429,
      "Rate limit exceeded. Please wait before sending another AI prompt.",
    );
  }
}

async function loadMessageHistory(
  client: ReturnType<typeof createUserClient>,
  conversationId: string,
) {
  const { data, error } = await client
    .from("ai_messages")
    .select("role, content, status, created_at")
    .eq("conversation_id", conversationId)
    .eq("status", "complete")
    .order("created_at", { ascending: false })
    .limit(HISTORY_LIMIT);

  if (error) throw error;

  return (data ?? [])
    .map((row) => row as Pick<MessageRow, "role" | "content">)
    .reverse();
}

async function buildSystemPrompt(
  client: ReturnType<typeof createUserClient>,
  conversation: ConversationRow,
  userId: string,
) {
  const ownerProfile = await loadOwnerProfile(client, userId);

  const baseRules = [
    "You are VitaGuard AI, a health-focused assistant inside the VitaGuard app.",
    "Provide calm, practical, safety-aware guidance in plain language.",
    "You are not a doctor and must not claim certainty, diagnosis, or emergency authority.",
    "If symptoms sound urgent or dangerous, tell the user to seek emergency or clinician help immediately.",
    "Do not invent patient facts. If the provided VitaGuard context is missing, say so.",
    "Keep replies concise, actionable, and medically cautious.",
  ].join("\n");

  if (conversation.role === "doctor") {
    return [
      baseRules,
      "This user is a doctor. Act as a generic clinical workflow assistant only.",
      "Do not reference any specific patient data unless it is explicitly included in the conversation.",
      `Doctor profile: ${JSON.stringify(ownerProfile)}`,
    ].join("\n\n");
  }

  if (!conversation.context_patient_id) {
    return [
      baseRules,
      `User profile: ${JSON.stringify(ownerProfile)}`,
      "No linked patient context is currently available.",
    ].join("\n\n");
  }

  const patientContext = await loadPatientContext(
    client,
    conversation.context_patient_id,
  );

  return [
    baseRules,
    `User profile: ${JSON.stringify(ownerProfile)}`,
    `Patient context: ${JSON.stringify(patientContext)}`,
    "Use the patient context only as supporting data for a helpful explanation or next-step guidance.",
  ].join("\n\n");
}

async function loadOwnerProfile(
  client: ReturnType<typeof createUserClient>,
  userId: string,
) {
  const { data, error } = await client
    .from("profiles")
    .select("id, role, name, email, phone")
    .eq("id", userId)
    .limit(1);

  if (error) throw error;
  if (!data || data.length === 0) {
    throw new HttpError(404, "User profile not found.");
  }

  return data[0] as ProfileRow;
}

async function loadPatientContext(
  client: ReturnType<typeof createUserClient>,
  patientId: string,
) {
  const [
    patientProfileResult,
    patientRecordResult,
    medicalHistoryResult,
    dailyReportResult,
    alertsResult,
    xrayResult,
    vitalsResult,
  ] = await Promise.all([
    client
      .from("profiles")
      .select("id, name, email, phone, role")
      .eq("id", patientId)
      .limit(1),
    client
      .from("patients")
      .select("id, gender, age, assigned_doctor_id")
      .eq("id", patientId)
      .limit(1),
    client
      .from("patient_medical_history")
      .select(
        "allergies, medications, chronic_diseases, surgeries, notes, updated_at",
      )
      .eq("patient_id", patientId)
      .limit(1),
    client
      .from("patient_daily_reports")
      .select(
        "report_date, heart_rate, oxygen_level, temperature, blood_pressure, tasks_activities, notes, created_at",
      )
      .eq("patient_id", patientId)
      .order("created_at", { ascending: false })
      .limit(1),
    client
      .from("medical_alerts")
      .select("alert_type, alert_data, created_at")
      .eq("patient_id", patientId)
      .eq("is_resolved", false)
      .order("created_at", { ascending: false })
      .limit(5),
    client
      .from("patient_xray_results")
      .select("prediction, confidence, report_text, created_at")
      .eq("patient_id", patientId)
      .order("created_at", { ascending: false })
      .limit(1),
    client
      .from("patient_live_vitals")
      .select("bpm, temperature, spo2, device_status, recorded_at")
      .eq("patient_id", patientId)
      .order("recorded_at", { ascending: false })
      .limit(10),
  ]);

  const results = [
    patientProfileResult,
    patientRecordResult,
    medicalHistoryResult,
    dailyReportResult,
    alertsResult,
    xrayResult,
    vitalsResult,
  ];

  for (const result of results) {
    if (result.error) throw result.error;
  }

  const patientProfile = patientProfileResult.data?.[0] ?? null;
  const patientRecord = patientRecordResult.data?.[0] ?? null;
  const medicalHistory = medicalHistoryResult.data?.[0] ?? null;
  const latestDailyReport = dailyReportResult.data?.[0] ?? null;
  const unresolvedAlerts = alertsResult.data ?? [];
  const latestXray = xrayResult.data?.[0] ?? null;
  const recentVitals = vitalsResult.data ?? [];

  return {
    patient_profile: patientProfile,
    patient_record: patientRecord,
    medical_history: medicalHistory,
    latest_daily_report: latestDailyReport,
    unresolved_alerts: unresolvedAlerts,
    latest_xray_result: latestXray,
    vitals_summary: summarizeVitals(recentVitals as Record<string, unknown>[]),
  };
}

function summarizeVitals(rows: Record<string, unknown>[]) {
  if (rows.length === 0) {
    return {
      sample_count: 0,
      latest: null,
      averages: null,
    };
  }

  const numericAverage = (values: number[]) =>
    values.length === 0
      ? null
      : Number(
        (values.reduce((sum, value) => sum + value, 0) / values.length).toFixed(
          1,
        ),
      );

  const bpms = rows
    .map((row) => Number(row["bpm"]))
    .filter((value) => Number.isFinite(value));
  const temperatures = rows
    .map((row) => Number(row["temperature"]))
    .filter((value) => Number.isFinite(value));
  const spo2Values = rows
    .map((row) => Number(row["spo2"]))
    .filter((value) => Number.isFinite(value));

  return {
    sample_count: rows.length,
    latest: rows[0],
    averages: {
      bpm: numericAverage(bpms),
      temperature: numericAverage(temperatures),
      spo2: numericAverage(spo2Values),
    },
  };
}

async function* streamGeminiText(args: {
  systemPrompt: string;
  history: Array<Pick<MessageRow, "role" | "content">>;
}) {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1/models/${GEMINI_MODEL}:streamGenerateContent?alt=sse`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY,
      },
      body: JSON.stringify({
        system_instruction: {
          parts: [{ text: args.systemPrompt }],
        },
        contents: args.history.map((message) => ({
          role: message.role === "assistant" ? "model" : "user",
          parts: [{ text: message.content }],
        })),
      }),
    },
  );

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Gemini API failed: ${body}`);
  }

  if (!response.body) {
    throw new Error("Gemini API returned no response body.");
  }

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  while (true) {
    const { value, done } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true }).replaceAll("\r\n", "\n");

    let boundary = buffer.indexOf("\n\n");
    while (boundary >= 0) {
      const event = buffer.slice(0, boundary).trim();
      buffer = buffer.slice(boundary + 2);

      const text = parseSseText(event);
      if (text) {
        yield text;
      }

      boundary = buffer.indexOf("\n\n");
    }
  }

  buffer += decoder.decode();
  const finalChunk = parseSseText(buffer.trim());
  if (finalChunk) {
    yield finalChunk;
  }
}

function parseSseText(event: string) {
  if (!event) return "";

  const dataLines = event
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.startsWith("data:"))
    .map((line) => line.replace(/^data:\s*/, "").trim());

  if (dataLines.length === 0) return "";

  const payloadText = dataLines.join("\n");
  if (payloadText === "[DONE]") return "";

  const payload = JSON.parse(payloadText);
  const responses = Array.isArray(payload) ? payload : [payload];

  return responses
    .map(extractTextFromGeminiResponse)
    .filter((text) => text.length > 0)
    .join("");
}

function extractTextFromGeminiResponse(response: unknown) {
  const candidates = Array.isArray((response as any)?.candidates)
    ? (response as any).candidates
    : [];

  return candidates
    .flatMap((candidate) =>
      Array.isArray(candidate?.content?.parts) ? candidate.content.parts : []
    )
    .map((part) => typeof part?.text === "string" ? part.text : "")
    .join("");
}

async function updateAssistantMessage(
  client: ReturnType<typeof createUserClient>,
  messageId: string,
  values: {
    content: string;
    status: "streaming" | "complete" | "error";
    error_message?: string | null;
  },
) {
  const { error } = await client
    .from("ai_messages")
    .update({
      content: values.content,
      status: values.status,
      error_message: values.error_message ?? null,
      updated_at: new Date().toISOString(),
    })
    .eq("id", messageId);

  if (error) throw error;
}

async function finalizeConversation(
  client: ReturnType<typeof createUserClient>,
  conversationId: string,
  lastMessage: string,
) {
  const now = new Date().toISOString();
  const { error } = await client
    .from("ai_conversations")
    .update({
      last_message: lastMessage,
      last_message_at: now,
      updated_at: now,
    })
    .eq("id", conversationId);

  if (error) throw error;
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
