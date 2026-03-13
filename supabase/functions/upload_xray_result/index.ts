import { supabase } from "../_shared/supabase_client.ts";
import { uploadBase64File, inferExtension } from "../_shared/upload.ts";

const MAX_BYTES = 10 * 1024 * 1024;
const ALLOWED_TYPES = ["image/jpeg", "image/png"];

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const patientId = payload?.patient_id as string | undefined;
    const filename = payload?.filename as string | undefined;
    const contentType = payload?.content_type as string | undefined;
    const data = payload?.data as string | undefined;
    const reportText = payload?.report_text as string | undefined;
    const prediction = payload?.prediction as string | undefined;
    const confidence = payload?.confidence as number | undefined;
    const resultId = payload?.result_id as string | undefined;

    if (!patientId || !filename || !contentType || !data) {
      return new Response(JSON.stringify({ error: "Missing required fields." }), {
        status: 400,
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
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});
