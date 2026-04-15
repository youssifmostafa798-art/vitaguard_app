import { supabase } from "./supabase_client.ts";

export async function getUserIdFromRequest(req: Request) {
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^[Bb]earer\s+/, "");
  if (!token) {
    throw new Error("Missing or malformed Authorization header.");
  }

  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) {
    throw new Error("Invalid auth token.");
  }
  return data.user.id;
}

export async function assertAdmin(userId: string) {
  const { data, error } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", userId)
    .limit(1);

  if (error) throw error;

  const role = Array.isArray(data) && data.length > 0 ? data[0].role : null;
  if (role !== "admin") {
    throw new Error("Admin access required.");
  }
}
