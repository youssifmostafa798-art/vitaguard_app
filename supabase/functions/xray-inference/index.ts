// @ts-nocheck – Deno runtime globals
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// --- Configuration ---
// --- Configuration ---
const PRIMARY_MODEL = "AhmedMIX/vitaguard-xray".trim();
const FALLBACK_MODEL = "google/vit-base-patch16-224".trim();

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  );

  const hfToken = (Deno.env.get('HF_TOKEN') ?? '').trim();
  if (!hfToken) {
    return new Response(JSON.stringify({ error: "HF_TOKEN not found" }), { 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }, 
      status: 500 
    });
  }

  let resultId: string | null = null;

  try {
    const body = await req.json();
    const { result_id } = body;
    resultId = result_id;

    console.log(`[DEEP_ROUTING] Stabilizing Analysis for: ${resultId}`);

    // 1. Fetch metadata & image
    const { data: resultRow, error: fetchErr } = await supabase
      .from('patient_xray_results')
      .select('image_path')
      .eq('id', resultId)
      .single();

    if (fetchErr || !resultRow?.image_path) throw new Error(`Record not found`);

    const { data: imgData, error: dlError } = await supabase
      .storage
      .from('xray-images')
      .download(resultRow.image_path);

    if (dlError) throw new Error(`Storage error: ${dlError.message}`);
    const imageBuffer = await imgData.arrayBuffer();

    // 2. RESILIENT MULTI-DOMAIN SHUFFLING & FALLBACK
    const models = [PRIMARY_MODEL, FALLBACK_MODEL];
    const baseUrls = [
      "https://api-inference.huggingface.co/models",
      "https://api-inference.hf.co/models",
      "https://huggingface.co/api/models"
    ];

    let predictions = null;
    let lastError = "";

    // Diagnostic DoH (DNS-over-HTTPS) Check
    try {
      const doh = await fetch("https://dns.google/resolve?name=api-inference.huggingface.co&type=A");
      const dohJson = await doh.json();
      console.log(`[DOH_DIAGNOSTIC] api-inference.huggingface.co IP: ${dohJson.Answer?.[0]?.data || "NOT_FOUND"}`);
    } catch (e: unknown) {
       console.warn(`[DOH_DIAGNOSTIC] DoH lookup itself failed: ${(e instanceof Error ? e.message : String(e))}`);
    }

    modelLoop: for (const model of models) {
      console.log(`[DEEP_ROUTING] Trying Model: ${model}`);
      
      for (const baseUrl of baseUrls) {
        const url = `${baseUrl}/${model}`;
        
        for (let attempt = 1; attempt <= 2; attempt++) {
          console.log(`[PROBE] Attempt ${attempt} -> ${url}`);
          
          const hfHeaders = new Headers({
            "Authorization": `Bearer ${hfToken}`,
            "Content-Type": "application/octet-stream",
            "Accept": "application/json"
          });

          try {
            const hfResponse = await fetch(url, { method: "POST", headers: hfHeaders, body: imageBuffer });

            if (hfResponse.ok) {
              predictions = await hfResponse.json();
              console.log(`[PROBE] SUCCESS at ${url}`);
              break modelLoop;
            } else {
              const server = hfResponse.headers.get("server") || "unknown";
              const errorText = await hfResponse.text();
              lastError = `Status: ${hfResponse.status} | Server: ${server} | Msg: ${errorText.substring(0, 40)}`;
              console.warn(`[PROBE] FAILED: ${lastError}`);
            }
          } catch (fetchErr) {
            lastError = `Network/DNS Error: ${fetchErr instanceof Error ? fetchErr.message : String(fetchErr)}`;
            console.warn(`[PROBE] CRASHED: ${lastError}`);
          }

          // Exponential backoff
          await new Promise(r => setTimeout(r, attempt * 1000));
        }
      }
    }

    if (!predictions) {
      throw new Error(`Strategic Blackout: All 3 domains and 2 models failed. Last error: ${lastError}`);
    }

    // 3. Process Result
    const sorted = Array.isArray(predictions) ? predictions.sort((a, b) => b.score - a.score) : [];
    const topResult = sorted[0];
    if (!topResult) throw new Error("AI returned empty result set");

    const prediction = topResult.label.toUpperCase();
    const confidence = topResult.score;

    const probPneu = sorted.find((p: any) => p.label.toUpperCase().includes('PNEUMONIA'))?.score ?? 0;
    const probNorm = sorted.find((p: any) => p.label.toUpperCase().includes('NORMAL') || p.label.toUpperCase().includes('NOT'))?.score ?? 0;

    const reportText = `Analysis complete. Findings suggest ${prediction.toLowerCase()}. (Confidence: ${(confidence * 100).toFixed(1)}%)`;

    // 4. Update Database
    if (resultId) {
      await supabase
        .from('patient_xray_results')
        .update({
          prediction: prediction,
          confidence: confidence,
          prob_normal: probNorm,
          prob_pneumonia: probPneu,
          report_text: reportText,
          engine_status: 'STABLE',
          processed_at: new Date().toISOString(),
        })
        .eq('id', resultId);
    }

    return new Response(JSON.stringify({ success: true, prediction, confidence, report_text: reportText }), { 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    });

  } catch (err) {
    console.error("[FATAL]", err);
    const errorMsg = `TECH_ERROR (DEEP_ROUTING_FAIL): ${err instanceof Error ? err.message : String(err)}`;
    
    if (resultId) {
       await supabase.from('patient_xray_results')
        .update({ prediction: 'INDETERMINATE', report_text: errorMsg, engine_status: 'ERROR' })
        .eq('id', resultId);
    }

    return new Response(JSON.stringify({ success: false, error: errorMsg }), { 
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }, 
      status: 200 
    });
  }
});
