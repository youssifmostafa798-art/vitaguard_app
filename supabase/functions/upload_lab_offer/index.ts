// @ts-nocheck – Deno runtime globals
import { supabase } from "../_shared/supabase_client.ts";
import { uploadBase64File, inferExtension } from "../_shared/upload.ts";

const MAX_BYTES = 5 * 1024 * 1024;
const ALLOWED_TYPES = ["image/jpeg", "image/png"];

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function validationError(details: string) {
  return jsonResponse({ error: "Invalid input", details }, 400);
}

Deno.serve(async (req: Request) => {
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
      return validationError(
        "Missing required fields: facility_id, offer_id, title, description, filename, content_type, and data are required.",
      );
    }

    if (!ALLOWED_TYPES.includes(contentType)) {
      return validationError("Offer cover image must be a JPEG or PNG.");
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

    return jsonResponse({ image_path: path, offer_id: offerId });
  } catch (error) {
    const err = error as {
      message?: string;
      code?: string;
      details?: string;
      hint?: string;
    };

    return jsonResponse({
      error: "Offer creation failed",
      details: err.message ?? "Unknown error",
      code: err.code,
      hint: err.hint,
      supabaseDetails: err.details,
    }, 400);
  }
});
