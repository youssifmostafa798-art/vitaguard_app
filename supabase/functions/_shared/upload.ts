import { supabase } from "./supabase_client.ts";

export type UploadOptions = {
  bucket: string;
  path: string;
  contentType: string;
  maxBytes: number;
  allowedTypes: string[];
  base64Data: string;
};

export async function uploadBase64File(options: UploadOptions) {
  const bytes = decodeBase64(options.base64Data);

  if (!options.allowedTypes.includes(options.contentType)) {
    throw new Error("Unsupported file type.");
  }

  if (bytes.length > options.maxBytes) {
    throw new Error("File too large.");
  }

  const { error } = await supabase.storage
    .from(options.bucket)
    .upload(options.path, bytes, {
      contentType: options.contentType,
      upsert: true,
    });

  if (error) {
    throw error;
  }
}

export function decodeBase64(data: string): Uint8Array {
  const binaryString = atob(data);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}

export function inferExtension(filename: string, contentType: string) {
  const lower = filename.toLowerCase();
  const dotIndex = lower.lastIndexOf(".");
  if (dotIndex >= 0) {
    return lower.substring(dotIndex);
  }

  switch (contentType) {
    case "image/jpeg":
      return ".jpg";
    case "image/png":
      return ".png";
    case "application/pdf":
      return ".pdf";
    default:
      return "";
  }
}
