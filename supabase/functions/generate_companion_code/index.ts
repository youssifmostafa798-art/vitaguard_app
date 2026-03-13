import { supabase } from "../_shared/supabase_client.ts";

const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

function randomCode(length = 6) {
  const bytes = crypto.getRandomValues(new Uint8Array(length));
  return Array.from(bytes, (b) => alphabet[b % alphabet.length]).join("");
}

Deno.serve(async () => {
  for (let attempt = 0; attempt < 10; attempt++) {
    const code = randomCode();
    const { data, error } = await supabase
      .from("patients")
      .select("id")
      .eq("companion_code", code)
      .limit(1);

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (Array.isArray(data) && data.length === 0) {
      return new Response(JSON.stringify({ code }), {
        headers: { "Content-Type": "application/json" },
      });
    }
  }

  return new Response(JSON.stringify({ error: "Failed to generate code." }), {
    status: 500,
    headers: { "Content-Type": "application/json" },
  });
});
