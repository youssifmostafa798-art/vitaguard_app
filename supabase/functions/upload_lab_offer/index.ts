import { supabase } from "../_shared/supabase_client.ts";
import { uploadBase64File, inferExtension } from "../_shared/upload.ts";

const MAX_BYTES = 5 * 1024 * 1024;
const ALLOWED_TYPES = ["image/jpeg", "image/png"];

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const facilityId = payload?.facility_id as string | undefined;
    const offerId = payload?.offer_id as string | undefined;
    const title = payload?.title as string | undefined;
    const description = payload?.description as string | undefined;
    const filename = payload?.filename as string | undefined;
    const contentType = payload?.content_type as string | undefined;
    const data = payload?.data as string | undefined;

    if (!facilityId || !offerId || !title || !description || !filename || !contentType || !data) {
      return new Response(JSON.stringify({ error: "Missing required fields." }), {
        status: 400,
      });
    }

    const ext = inferExtension(filename, contentType);
    const path = `${facilityId}/${offerId}${ext}`;

    await uploadBase64File({
      bucket: "lab-offers",
      path,
      contentType,
      maxBytes: MAX_BYTES,
      allowedTypes: ALLOWED_TYPES,
      base64Data: data,
    });

    const { error } = await supabase.from("facility_offers").insert({
      id: offerId,
      facility_id: facilityId,
      title,
      description,
      image_path: path,
      is_active: true,
    });

    if (error) throw error;

    return new Response(JSON.stringify({ image_path: path, offer_id: offerId }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});
