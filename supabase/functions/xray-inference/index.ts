import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"
import * as ort from "https://esm.sh/onnxruntime-web@1.19.0?target=deno"
import { Image } from "https://deno.land/x/imagescript@1.2.15/mod.ts"

// ENFORCE SINGLE THREADED & NO-SIMD EXECUTION GLOBALLY
ort.env.wasm.numThreads = 1;
ort.env.wasm.simd = false;
ort.env.wasm.proxy = false; 
ort.env.wasm.wasmPaths = "https://cdn.jsdelivr.net/npm/onnxruntime-web@1.19.0/dist/";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

let modelSession: ort.InferenceSession | null = null;

/**
 * Loads the ONNX model from Supabase Storage securely.
 * Caches the session in memory to avoid redundant downloads.
 */
async function loadModel(supabase: any) {
  if (modelSession) {
    console.log("[TRACE] Model cache hit. Session ready.");
    return modelSession;
  }

  console.log("[TRACE] Model cache miss. Downloading 33MB model from storage (ai-models/model.onnx)...");
  
  const { data: modelData, error } = await supabase
    .storage
    .from('ai-models')
    .download('model.onnx');

  if (error) {
    console.error("[CRITICAL] Model download failed:", error);
    throw new Error(`AI Model unavailable: ${error.message}. Please ensure 'model.onnx' is in the 'ai-models' bucket.`);
  }

  console.log("[TRACE] Model downloaded. Initializing ONNX runtime (WASM)...");
  const modelBuffer = await modelData.arrayBuffer();
  
  modelSession = await ort.InferenceSession.create(modelBuffer, {
    executionProviders: ["wasm"],
    graphOptimizationLevel: "all",
  });

  console.log("[TRACE] Inference session initialized and cached.");
  return modelSession;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  );

  let resultId: string | null = null;

  try {
    const body = await req.json();
    const { image_url, result_id } = body;
    resultId = result_id;
    console.log(`[TRACE] Processing Request: ${resultId}`);

    // 1. Authenticated Download (Secure)
    console.log("[TRACE] Fetching image path from database...");
    const { data: resultRow, error: fetchErr } = await supabase
      .from('patient_xray_results')
      .select('image_path')
      .eq('id', resultId)
      .single();

    if (fetchErr || !resultRow?.image_path) {
      throw new Error(`Failed to find image_path for result_id: ${resultId}. Error: ${fetchErr?.message}`);
    }

    console.log(`[TRACE] Downloading image from storage: ${resultRow.image_path}`);
    const { data: imgData, error: dlError } = await supabase
      .storage
      .from('xray-images')
      .download(resultRow.image_path);

    if (dlError) throw new Error(`Storage download failed: ${dlError.message}`);

    const imageBuffer = await imgData.arrayBuffer();
    if (imageBuffer.byteLength < 100) {
      throw new Error(`Downloaded image buffer is too small (${imageBuffer.byteLength} bytes). Possible corrupted file.`);
    }

    console.log("[TRACE] Decoding Image (ImageScript)...");
    const image = await Image.decode(imageBuffer);
    image.resize(224, 224);
    
    const float32Data = new Float32Array(3 * 224 * 224);
    
    // imagescript uses a Uint8Array '.bitmap' in RGBA format
    for (let i = 0; i < 224 * 224; i++) {
        const r = image.bitmap[i * 4];
        const g = image.bitmap[i * 4 + 1];
        const b = image.bitmap[i * 4 + 2];
        
        float32Data[i] = (r / 255.0 - 0.485) / 0.229;
        float32Data[i + 224 * 224] = (g / 255.0 - 0.456) / 0.224;
        float32Data[i + 2 * 224 * 224] = (b / 255.0 - 0.406) / 0.225;
    }

    let prediction = 'NORMAL';
    let confidence = 0.5;
    let probs = [0.5, 0.5];
    let inferenceError = false;
    let techErrorMessage = "";

    try {
      const activeSession = await loadModel(supabase);
      const tensor = new ort.Tensor('float32', float32Data, [1, 3, 224, 224]);
      const feeds = { input: tensor };
      const results = await activeSession.run(feeds);
      
      const output = results.output.data as Float32Array;
      const exp = output.map(v => Math.exp(v));
      const sum = exp.reduce((a, b) => a + b, 0);
      probs = exp.map(v => v / sum);

      prediction = probs[1] > probs[0] ? 'PNEUMONIA' : 'NORMAL';
      const rawConfidence = Math.max(...probs);
      confidence = rawConfidence >= 1.0 ? 0.999 : rawConfidence;
    } catch (engineErr) {
      console.error("[CRITICAL] Engine failure:", engineErr);
      inferenceError = true;
      techErrorMessage = `TECH_ERROR: ${engineErr instanceof Error ? engineErr.message : String(engineErr)}`;
      prediction = 'INDETERMINATE';
    }

    const reportText = inferenceError 
        ? techErrorMessage 
        : `AI analysis suggests a scan characteristic of ${prediction.toLowerCase()}.`;

    // Update DB with results
    if (resultId) {
      await supabase
        .from('patient_xray_results')
        .update({
          prediction: prediction,
          confidence: confidence,
          prob_normal: probs[0],
          prob_pneumonia: probs[1],
          report_text: reportText,
          engine_status: inferenceError ? 'ERROR' : 'STABLE',
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
        normal_prob: probs[0],
        pneumonia_prob: probs[1]
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err) {
    console.error("[FATAL] Function crash:", err);
    const fatalErrorMsg = `TECH_ERROR (PANIC): ${err instanceof Error ? err.message : String(err)}`;
    
    // Try one last time to update DB so UI sees the error
    if (resultId) {
       await supabase
        .from('patient_xray_results')
        .update({
          prediction: 'INDETERMINATE',
          report_text: fatalErrorMsg,
          engine_status: 'FATAL_ERROR',
          processed_at: new Date().toISOString(),
        })
        .eq('id', resultId);
    }

    // Return 200 so Flutter app doesn't show the Red "unavailable" screen
    return new Response(
      JSON.stringify({ 
        success: false, 
        prediction: 'INDETERMINATE', 
        error: fatalErrorMsg,
        report_text: fatalErrorMsg 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    );
  }
});
