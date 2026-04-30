// @ts-nocheck – Deno runtime globals
import { supabase } from "../_shared/supabase_client.ts";
import { uploadBase64File, inferExtension } from "../_shared/upload.ts";

const MAX_BYTES = 10 * 1024 * 1024;
const ALLOWED_TYPES = ["image/jpeg", "image/png", "application/pdf"];

Deno.serve(async (req: Request) => {
  try {
    const payload = await req.json();
    const patientId = payload?.patient_id as string | undefined;
    const documentId = payload?.document_id as string | undefined;
    const filename = payload?.filename as string | undefined;
    const contentType = payload?.content_type as string | undefined;
    const data = payload?.data as string | undefined;

    if (!patientId || !documentId || !filename || !contentType || !data) {
      return new Response(JSON.stringify({ error: "Missing required fields." }), {
        status: 400,
      });
    }

    const ext = inferExtension(filename, contentType);
    const path = `${patientId}/${documentId}${ext}`;

    await uploadBase64File({
      bucket: "medical-records",
      path,
      contentType,
      maxBytes: MAX_BYTES,
      allowedTypes: ALLOWED_TYPES,
      base64Data: data,
    });

    const { error } = await supabase.from("patient_documents").insert({
      id: documentId,
      patient_id: patientId,
      file_path: path,
      document_type: contentType === "application/pdf" ? "pdf" : "image",
      original_filename: filename,
    });

    if (error) throw error;

    return new Response(JSON.stringify({ file_path: path, document_id: documentId }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});
