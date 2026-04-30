// @ts-nocheck – Deno runtime globals
import { supabase } from "../_shared/supabase_client.ts";
import { assertAdmin, getUserIdFromRequest } from "../_shared/auth.ts";

Deno.serve(async (req: Request) => {
  try {
    const userId = await getUserIdFromRequest(req);
    await assertAdmin(userId);

    const payload = await req.json();
    const doctorId = payload?.doctorId as string | undefined;
    const status = payload?.status as string | undefined;

    if (!doctorId || !status) {
      return new Response(JSON.stringify({ error: "doctorId and status required." }), {
        status: 400,
      });
    }

    if (!["approved", "rejected"].includes(status)) {
      return new Response(JSON.stringify({ error: "Invalid status." }), { status: 400 });
    }

    const { error } = await supabase.from("doctors").update({
      verification_status: status,
      reviewed_by: userId,
      reviewed_at: new Date().toISOString(),
    }).eq("id", doctorId);

    if (error) throw error;

    return new Response(JSON.stringify({ doctorId, verificationStatus: status }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }
});
