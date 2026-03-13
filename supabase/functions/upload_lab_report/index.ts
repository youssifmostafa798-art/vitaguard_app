import { supabase } from "../_shared/supabase_client.ts";
import { uploadBase64File, inferExtension } from "../_shared/upload.ts";

const MAX_BYTES = 10 * 1024 * 1024;
const ALLOWED_TYPES = ["image/jpeg", "image/png", "application/pdf"];

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const facilityId = payload?.facility_id as string | undefined;
    const patientId = payload?.patient_id as string | undefined;
    const reportId = payload?.report_id as string | undefined;
    const testType = payload?.test_type as string | undefined;
    const notes = payload?.notes as string | undefined;
    const filename = payload?.filename as string | undefined;
    const contentType = payload?.content_type as string | undefined;
    const data = payload?.data as string | undefined;

    if (!facilityId || !reportId || !testType || !filename || !contentType || !data) {
      return new Response(JSON.stringify({ error: "Missing required fields." }), {
        status: 400,
      });
    }

    const ext = inferExtension(filename, contentType);
    const path = `${facilityId}/${reportId}${ext}`;

    await uploadBase64File({
      bucket: "lab-reports",
      path,
      contentType,
      maxBytes: MAX_BYTES,
      allowedTypes: ALLOWED_TYPES,
      base64Data: data,
    });

    const { error } = await supabase.from("facility_tests").insert({
      id: reportId,
      facility_id: facilityId,
      patient_id: patientId,
      test_type: testType,
      file_path: path,
      notes,
    });

    if (error) throw error;

    return new Response(JSON.stringify({ file_path: path, report_id: reportId }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});
