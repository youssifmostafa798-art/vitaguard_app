import { supabase } from "../_shared/supabase_client.ts";
import { uploadBase64File, inferExtension } from "../_shared/upload.ts";
import { corsHeaders } from "../_shared/cors.ts";

const MAX_BYTES = 10 * 1024 * 1024;
const ALLOWED_TYPES = ["image/jpeg", "image/png"];

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const payload = await req.json();
    console.log("Received payload keys:", Object.keys(payload));
    
    const patientId = payload?.patient_id as string | undefined;
    const filename = payload?.filename as string | undefined;
    const contentType = payload?.content_type as string | undefined;
    const data = payload?.data as string | undefined;
    const reportText = payload?.report_text as string | undefined;
    const prediction = payload?.prediction as string | undefined;
    const confidence = payload?.confidence as number | undefined;
    const resultId = payload?.result_id as string | undefined;

    if (!patientId || !filename || !contentType || !data) {
      const missing = [];
      if (!patientId) missing.push("patient_id");
      if (!filename) missing.push("filename");
      if (!contentType) missing.push("content_type");
      if (!data) missing.push("data");
      
      return new Response(JSON.stringify({ 
        error: `Missing required fields: ${missing.join(", ")}` 
      }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const ext = inferExtension(filename, contentType);
    const xrayId = resultId ?? crypto.randomUUID();
    const path = `${patientId}/${xrayId}${ext}`;

    await uploadBase64File({
      bucket: "xray-results",
      path,
      contentType,
      maxBytes: MAX_BYTES,
      allowedTypes: ALLOWED_TYPES,
      base64Data: data,
    });

    const { error } = await supabase.from("patient_xray_results").insert({
      id: xrayId,
      patient_id: patientId,
      is_valid: true,
      prediction,
      confidence,
      report_text: reportText,
      image_path: path,
    });

    if (error) throw error;

    return new Response(JSON.stringify({ image_path: path, result_id: xrayId }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const errorDetails = error instanceof Error ? {
      message: error.message,
      stack: error.stack,
      name: error.name
    } : { error: String(error) };

    return new Response(JSON.stringify({ 
      error: "Internal Function Error", 
      details: errorDetails 
    }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
