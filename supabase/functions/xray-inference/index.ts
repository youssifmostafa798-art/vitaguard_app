import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// --- Configuration ---
// Switch to a foundational model known for 100% uptime on the free Inference API
const HF_MODEL = "google/vit-base-patch16-224";
const HF_API_URL = `https://api-inference.huggingface.co/models/${HF_MODEL}`;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  );

  const hfToken = Deno.env.get('HF_TOKEN');
  if (!hfToken) {
    return new Response(
      JSON.stringify({ error: "HF_TOKEN not found in Supabase Secrets. Please run 'supabase secrets set HF_TOKEN=...'" }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }

  let resultId: string | null = null;

  try {
    const body = await req.json();
    const { result_id } = body;
    resultId = result_id;

    console.log(`[TRACE] Proxying Analysis for result_id: ${resultId}`);

    // 1. Fetch image path from database
    const { data: resultRow, error: fetchErr } = await supabase
      .from('patient_xray_results')
      .select('image_path')
      .eq('id', resultId)
      .single();

    if (fetchErr || !resultRow?.image_path) {
      throw new Error(`Record not found for result_id: ${resultId}`);
    }

    // 2. Download image from storage
    console.log(`[TRACE] Downloading image: ${resultRow.image_path}`);
    const { data: imgData, error: dlError } = await supabase
      .storage
      .from('xray-images')
      .download(resultRow.image_path);

    if (dlError) throw new Error(`Storage download failed: ${dlError.message}`);
    const imageBuffer = await imgData.arrayBuffer();

    // 3. Delegate to Hugging Face
    console.log(`[TRACE] Sending to Hugging Face (${HF_MODEL})...`);
    
    // CRITICAL: Construct clean headers to avoid 404 routing issues 
    // (Supabase adds X-Forwarded-Host which HF dislikes)
    const hfHeaders = new Headers();
    hfHeaders.set("Authorization", `Bearer ${hfToken}`);
    hfHeaders.set("Content-Type", "application/octet-stream");
    hfHeaders.set("User-Agent", "VitaGuard-Clinical-AI/1.0");

    const hfResponse = await fetch(HF_API_URL, {
      method: "POST",
      headers: hfHeaders,
      body: imageBuffer,
    });

    if (!hfResponse.ok) {
      const errorText = await hfResponse.text();
      throw new Error(`Hugging Face API error: ${hfResponse.status} - ${errorText}`);
    }

    const predictions = await hfResponse.json();
    console.log("[TRACE] HF Raw Response:", JSON.stringify(predictions));

    // HF Response Format: [{"label": "PNEUMONIA", "score": 0.99}, ...]
    // Sort to find top prediction
    const topResult = predictions.sort((a: any, b: any) => b.score - a.score)[0];
    const prediction = topResult.label.toUpperCase();
    const confidence = topResult.score;

    // Map probabilities for DB
    const probPneu = predictions.find((p: any) => p.label.toUpperCase() === 'PNEUMONIA')?.score ?? 0;
    const probNorm = predictions.find((p: any) => p.label.toUpperCase() === 'NORMAL' || p.label.toUpperCase() === 'NOT PNEUMONIA')?.score ?? 0;

    const reportText = `AI analysis (Hugging Face) suggests findings characteristic of ${prediction.toLowerCase()}. Confidence: ${(confidence * 100).toFixed(1)}%.`;

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

    return new Response(
      JSON.stringify({ 
        success: true, 
        prediction, 
        confidence, 
        report_text: reportText,
        probs: predictions
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error("[FATAL] Function crash:", err);
    const errorMsg = `TECH_ERROR (HF_PROXY): ${err instanceof Error ? err.message : String(err)}`;
    
    if (resultId) {
       await supabase
        .from('patient_xray_results')
        .update({
          prediction: 'INDETERMINATE',
          report_text: errorMsg,
          engine_status: 'ERROR',
        })
        .eq('id', resultId);
    }

    return new Response(
      JSON.stringify({ success: false, error: errorMsg }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    );
  }
});
