// @ts-nocheck – Deno runtime globals
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { supabase } from "../_shared/supabase_client.ts";

const SPO2_WARNING = 92;
const SPO2_CRITICAL = 89;
const HEART_RATE_LOW = 60;
const HEART_RATE_HIGH = 120;
const TEMPERATURE_WARNING = 38.5;
const TEMPERATURE_CRITICAL = 39.5;

const CRITICAL_DEVICE_STATUSES = new Set([
  "FALL_DETECTED",
  "EMERGENCY_BUTTON",
  "EMERGENCY_NO_PULSE",
]);

type AlertSeverity = "warning" | "critical";

type IncomingTelemetry = {
  device_id?: string;
  patient_id?: string;
  source_event_id?: string;
  vitals?: {
    bpm?: number | string | null;
    temperature?: number | string | null;
    spo2?: number | string | null;
  };
  motion?: {
    fall_detected?: boolean | null;
    acc_z?: number | string | null;
  };
  device_status?: string | null;
  timestamp?: string | null;
};

type NormalizedTelemetry = {
  deviceId: string;
  patientId: string;
  sourceEventId: string;
  recordedAt: string;
  bpm: number | null;
  temperature: number | null;
  spo2: number | null;
  fallDetected: boolean;
  accZ: number | null;
  deviceStatus: string | null;
};

type AlertCandidate = {
  alertType: string;
  severity: AlertSeverity;
  metrics: string[];
  message: string;
  payload: Record<string, unknown>;
  dedupeKey: string;
};

type Recipient = {
  userId: string;
  role: "companion" | "doctor";
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return jsonResponse({ ok: true });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      { error: "Method not allowed. Use POST." },
      405,
    );
  }

  try {
    authorizeHardwareRequest(req);

    const payload = (await req.json()) as IncomingTelemetry;
    const telemetry = normalizeTelemetry(payload);

    const duplicateVitals = await findExistingVitals(telemetry);
    if (duplicateVitals) {
      return jsonResponse({
        success: true,
        deduplicated: true,
        vitalsId: duplicateVitals.id,
        alertsProcessed: 0,
      });
    }

    const vitalsRow = await insertLiveVitals(telemetry);
    const alertCandidates = buildAlertCandidates(telemetry);
    const persistedAlerts = [];

    for (const candidate of alertCandidates) {
      const alert = await persistAlertCandidate(telemetry, candidate);
      persistedAlerts.push(alert);
      await ensureAlertDeliveries(alert.id, telemetry.patientId, candidate.severity);
    }

    return jsonResponse({
      success: true,
      deduplicated: false,
      vitalsId: vitalsRow.id,
      alertsProcessed: persistedAlerts.length,
      alertIds: persistedAlerts.map((alert) => alert.id),
    });
  } catch (error) {
    console.error("hardware_telemetry failure", error);
    return jsonResponse(
      {
        error: error instanceof Error ? error.message : "Unknown error",
      },
      400,
    );
  }
});

function authorizeHardwareRequest(req: Request) {
  const hardwareApiKey = Deno.env.get("HARDWARE_API_KEY");
  if (!hardwareApiKey) {
    return;
  }

  const requestKey = req.headers.get("X-Hardware-Key");
  if (requestKey !== hardwareApiKey) {
    throw new Error("Unauthorized: Invalid hardware key.");
  }
}

function normalizeTelemetry(payload: IncomingTelemetry): NormalizedTelemetry {
  const deviceId = payload.device_id?.trim();
  const patientId = payload.patient_id?.trim();

  if (!deviceId || !patientId) {
    throw new Error("Missing required fields: device_id and patient_id.");
  }

  const recordedAt = parseTimestamp(payload.timestamp);
  const sourceEventId = payload.source_event_id?.trim()
    || `${deviceId}:${recordedAt}`;

  return {
    deviceId,
    patientId,
    sourceEventId,
    recordedAt,
    bpm: asNumber(payload.vitals?.bpm),
    temperature: asNumber(payload.vitals?.temperature),
    spo2: asNumber(payload.vitals?.spo2),
    fallDetected: payload.motion?.fall_detected === true,
    accZ: asNumber(payload.motion?.acc_z),
    deviceStatus: payload.device_status?.trim() || null,
  };
}

function parseTimestamp(raw: string | null | undefined) {
  const parsed = raw ? new Date(raw) : new Date();
  if (Number.isNaN(parsed.getTime())) {
    throw new Error("Invalid timestamp.");
  }
  return parsed.toISOString();
}

function asNumber(value: number | string | null | undefined) {
  if (value === null || value === undefined || value === "") {
    return null;
  }

  const normalized = typeof value === "string" ? Number(value) : value;
  if (!Number.isFinite(normalized)) {
    return null;
  }

  return Number(normalized);
}

async function findExistingVitals(telemetry: NormalizedTelemetry) {
  const { data, error } = await supabase
    .from("patient_live_vitals")
    .select("id")
    .eq("patient_id", telemetry.patientId)
    .eq("source_event_id", telemetry.sourceEventId)
    .limit(1)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data;
}

async function insertLiveVitals(telemetry: NormalizedTelemetry) {
  const { data, error } = await supabase
    .from("patient_live_vitals")
    .insert({
      patient_id: telemetry.patientId,
      device_id: telemetry.deviceId,
      bpm: telemetry.bpm,
      temperature: telemetry.temperature,
      spo2: telemetry.spo2,
      device_status: telemetry.deviceStatus,
      recorded_at: telemetry.recordedAt,
      source_event_id: telemetry.sourceEventId,
    })
    .select("id")
    .single();

  if (error) {
    throw error;
  }

  return data;
}

function buildAlertCandidates(telemetry: NormalizedTelemetry): AlertCandidate[] {
  const alerts: AlertCandidate[] = [];

  if (telemetry.deviceStatus && CRITICAL_DEVICE_STATUSES.has(telemetry.deviceStatus)) {
    alerts.push({
      alertType: telemetry.deviceStatus,
      severity: "critical",
      metrics: [telemetry.deviceStatus],
      message: emergencyMessage(telemetry.deviceStatus),
      payload: buildPayload(telemetry, {
        deviceStatus: telemetry.deviceStatus,
      }),
      dedupeKey: `device:${telemetry.deviceStatus.toLowerCase()}`,
    });
  }

  if (telemetry.fallDetected || isAbruptFall(telemetry.accZ)) {
    alerts.push({
      alertType: "FALL_DETECTED",
      severity: "critical",
      metrics: ["Motion"],
      message: "Critical fall detected. Immediate physical response is required.",
      payload: buildPayload(telemetry, {
        fall_detected: telemetry.fallDetected,
        acc_z: telemetry.accZ,
      }),
      dedupeKey: "motion:fall-detected",
    });
  }

  const hasRespiratoryCardiacRisk = telemetry.spo2 !== null
    && telemetry.spo2 < SPO2_WARNING
    && telemetry.bpm !== null
    && telemetry.bpm > HEART_RATE_HIGH;

  if (hasRespiratoryCardiacRisk) {
    alerts.push({
      alertType: "RESPIRATORY_CARDIAC_RISK",
      severity: "critical",
      metrics: ["SpO2", "Heart Rate"],
      message: `Critical respiratory strain detected: SpO2 ${telemetry.spo2}% with heart rate ${telemetry.bpm} bpm.`,
      payload: buildPayload(telemetry, {}),
      dedupeKey: "combined:respiratory-cardiac-risk",
    });
  }

  if (telemetry.spo2 !== null) {
    if (telemetry.spo2 < SPO2_CRITICAL) {
      alerts.push({
        alertType: "LOW_OXYGEN_CRITICAL",
        severity: "critical",
        metrics: ["SpO2"],
        message: `Critical oxygen saturation detected: ${telemetry.spo2}%.`,
        payload: buildPayload(telemetry, {}),
        dedupeKey: "spo2:critical",
      });
    } else if (telemetry.spo2 < SPO2_WARNING) {
      alerts.push({
        alertType: "LOW_OXYGEN_WARNING",
        severity: "warning",
        metrics: ["SpO2"],
        message: `Low oxygen saturation detected: ${telemetry.spo2}%.`,
        payload: buildPayload(telemetry, {}),
        dedupeKey: "spo2:warning",
      });
    }
  }

  if (telemetry.bpm !== null) {
    if (telemetry.bpm > HEART_RATE_HIGH) {
      alerts.push({
        alertType: "HEART_RATE_HIGH",
        severity: "warning",
        metrics: ["Heart Rate"],
        message: `Heart rate is elevated at ${telemetry.bpm} bpm.`,
        payload: buildPayload(telemetry, {}),
        dedupeKey: "bpm:high",
      });
    } else if (telemetry.bpm < HEART_RATE_LOW) {
      alerts.push({
        alertType: "HEART_RATE_LOW",
        severity: "warning",
        metrics: ["Heart Rate"],
        message: `Heart rate is low at ${telemetry.bpm} bpm.`,
        payload: buildPayload(telemetry, {}),
        dedupeKey: "bpm:low",
      });
    }
  }

  if (telemetry.temperature !== null) {
    if (telemetry.temperature > TEMPERATURE_CRITICAL) {
      alerts.push({
        alertType: "HIGH_FEVER_CRITICAL",
        severity: "critical",
        metrics: ["Temperature"],
        message: `Critical fever detected at ${telemetry.temperature.toFixed(1)} C.`,
        payload: buildPayload(telemetry, {}),
        dedupeKey: "temp:critical",
      });
    } else if (telemetry.temperature > TEMPERATURE_WARNING) {
      alerts.push({
        alertType: "FEVER_WARNING",
        severity: "warning",
        metrics: ["Temperature"],
        message: `Elevated temperature detected at ${telemetry.temperature.toFixed(1)} C.`,
        payload: buildPayload(telemetry, {}),
        dedupeKey: "temp:warning",
      });
    }
  }

  return uniqueByDedupeKey(alerts);
}

function buildPayload(
  telemetry: NormalizedTelemetry,
  overrides: Record<string, unknown>,
) {
  return {
    bpm: telemetry.bpm,
    spo2: telemetry.spo2,
    temperature: telemetry.temperature,
    device_status: telemetry.deviceStatus,
    recorded_at: telemetry.recordedAt,
    source_event_id: telemetry.sourceEventId,
    ...overrides,
  };
}

function emergencyMessage(status: string) {
  switch (status) {
    case "FALL_DETECTED":
      return "Critical fall detected. Companion intervention is required.";
    case "EMERGENCY_BUTTON":
      return "Emergency button pressed. Immediate assistance is required.";
    case "EMERGENCY_NO_PULSE":
      return "No pulse detected. Immediate emergency response is required.";
    default:
      return `Critical hardware alert: ${status}.`;
  }
}

function isAbruptFall(accZ: number | null) {
  return accZ !== null && (accZ > 15 || accZ < 2);
}

function uniqueByDedupeKey(candidates: AlertCandidate[]) {
  const seen = new Set<string>();
  return candidates.filter((candidate) => {
    if (seen.has(candidate.dedupeKey)) {
      return false;
    }

    seen.add(candidate.dedupeKey);
    return true;
  });
}

async function persistAlertCandidate(
  telemetry: NormalizedTelemetry,
  candidate: AlertCandidate,
) {
  const { data: existingAlert, error: existingError } = await supabase
    .from("medical_alerts")
    .select(`
      id,
      patient_id,
      dedupe_key,
      is_resolved
    `)
    .eq("patient_id", telemetry.patientId)
    .eq("dedupe_key", candidate.dedupeKey)
    .eq("is_resolved", false)
    .order("occurred_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (existingError) {
    throw existingError;
  }

  if (existingAlert) {
    const { data, error } = await supabase
      .from("medical_alerts")
      .update({
        alert_type: candidate.alertType,
        alert_data: candidate.payload,
        severity: candidate.severity,
        source: "hardware",
        metrics: candidate.metrics,
        message: candidate.message,
        payload: candidate.payload,
        last_seen_at: telemetry.recordedAt,
        source_event_id: telemetry.sourceEventId,
      })
      .eq("id", existingAlert.id)
      .select("id")
      .single();

    if (error) {
      throw error;
    }

    return data;
  }

  const { data, error } = await supabase
    .from("medical_alerts")
    .insert({
      patient_id: telemetry.patientId,
      alert_type: candidate.alertType,
      alert_data: candidate.payload,
      severity: candidate.severity,
      source: "hardware",
      metrics: candidate.metrics,
      message: candidate.message,
      payload: candidate.payload,
      dedupe_key: candidate.dedupeKey,
      occurred_at: telemetry.recordedAt,
      last_seen_at: telemetry.recordedAt,
      source_event_id: telemetry.sourceEventId,
      is_resolved: false,
    })
    .select("id")
    .single();

  if (error) {
    throw error;
  }

  return data;
}

async function ensureAlertDeliveries(
  alertId: string,
  patientId: string,
  severity: AlertSeverity,
) {
  const recipients = await resolveRecipients(patientId, severity);
  if (recipients.length === 0) {
    return;
  }

  const now = new Date().toISOString();
  const rows = recipients.map((recipient) => ({
    alert_id: alertId,
    recipient_user_id: recipient.userId,
    recipient_role: recipient.role,
    delivery_status: "delivered",
    delivered_at: now,
    updated_at: now,
  }));

  const { error } = await supabase
    .from("medical_alert_deliveries")
    .upsert(rows, {
      onConflict: "alert_id,recipient_user_id,recipient_role",
      ignoreDuplicates: false,
    });

  if (error) {
    throw error;
  }
}

async function resolveRecipients(
  patientId: string,
  severity: AlertSeverity,
): Promise<Recipient[]> {
  const recipients: Recipient[] = [];

  const { data: companionRows, error: companionError } = await supabase
    .from("companions")
    .select("id")
    .eq("linked_patient_id", patientId);

  if (companionError) {
    throw companionError;
  }

  for (const companion of companionRows ?? []) {
    if (typeof companion.id === "string") {
      recipients.push({
        userId: companion.id,
        role: "companion",
      });
    }
  }

  if (severity === "critical") {
    const { data: patientRow, error: patientError } = await supabase
      .from("patients")
      .select("assigned_doctor_id")
      .eq("id", patientId)
      .limit(1)
      .maybeSingle();

    if (patientError) {
      throw patientError;
    }

    if (typeof patientRow?.assigned_doctor_id === "string") {
      recipients.push({
        userId: patientRow.assigned_doctor_id,
        role: "doctor",
      });
    }
  }

  return uniqueRecipients(recipients);
}

function uniqueRecipients(recipients: Recipient[]) {
  const seen = new Set<string>();
  return recipients.filter((recipient) => {
    const key = `${recipient.role}:${recipient.userId}`;
    if (seen.has(key)) {
      return false;
    }

    seen.add(key);
    return true;
  });
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
    status,
  });
}
