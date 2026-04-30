// @ts-nocheck – Deno runtime globals
import { supabase } from "../_shared/supabase_client.ts";
import { uploadBase64File, inferExtension } from "../_shared/upload.ts";

const MAX_BYTES = 5 * 1024 * 1024;
const ALLOWED_TYPES = ["image/jpeg", "image/png"];

Deno.serve(async (req: Request) => {
  try {
    const payload = await req.json();
    const doctorId = payload?.doctor_id as string | undefined;
    const filename = payload?.filename as string | undefined;
    const contentType = payload?.content_type as string | undefined;
    const data = payload?.data as string | undefined;

    if (!doctorId || !filename || !contentType || !data) {
      return new Response(JSON.stringify({ error: "Missing required fields." }), {
        status: 400,
      });
    }

    const ext = inferExtension(filename, contentType);
    const path = `${doctorId}/id_card${ext}`;

    await uploadBase64File({
      bucket: "doctor-verifications",
      path,
      contentType,
      maxBytes: MAX_BYTES,
      allowedTypes: ALLOWED_TYPES,
      base64Data: data,
    });

    const { error } = await supabase.from("doctors").update({
      id_card_path: path,
      verification_status: "pending",
    }).eq("id", doctorId);

    if (error) throw error;

    return new Response(JSON.stringify({ id_card_path: path }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});
