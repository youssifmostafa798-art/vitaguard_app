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

let session: any = null;

async function loadModel() {
  if (session) return session;

  try {
    console.log("[DIAG] Deno Memory Usage:", Deno.memoryUsage());
    const modelUrl = new URL("./Model.onnx", import.meta.url);
    console.log("[DIAG] Checking local model file:", modelUrl.toString());
    
    const fileStat = await Deno.stat(modelUrl);
    console.log(`[DIAG] Model file size: ${fileStat.size} bytes`);

    const modelBuffer = await Deno.readFile(modelUrl);
    console.log("[TRACE] Model read. Creating session (WASM)...");

    const sessionPromise = ort.InferenceSession.create(modelBuffer, {
      executionProviders: ['wasm'],
      graphOptimizationLevel: 'disabled',
    });

    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error("ONNX Session creation timed out (15s)")), 15000)
    );

    session = await Promise.race([sessionPromise, timeoutPromise]);
    console.log("[TRACE] ONNX Session Ready.");
    return session;
  } catch (err) {
    console.error("[CRITICAL] ONNX failure details:", err);
    throw err;
  }
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
    console.log(`[TRACE] Processing Request: ${result_id}`);

    const imageUrl = new URL(image_url);
    const response = await fetch(imageUrl);
    const imageBuffer = await response.arrayBuffer();
    
    console.log("[TRACE] Decoding Image...");
    const image = await Image.decode(imageBuffer);
    image.resize(224, 224);
    
    const float32Data = new Float32Array(3 * 224 * 224);
    const pixels = image.getFlattened();
    
    for (let i = 0; i < 224 * 224; i++) {
        const pixel = pixels[i];
        const r = (pixel >> 24) & 0xff;
        const g = (pixel >> 16) & 0xff;
        const b = (pixel >> 8) & 0xff;
        
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
      const modelSession = await loadModel();
      const tensor = new ort.Tensor('float32', float32Data, [1, 3, 224, 224]);
      const feeds = { input: tensor };
      const results = await modelSession.run(feeds);
      
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

    // Update DB with results
    if (resultId) {
      await supabase
        .from('patient_xray_results')
        .update({
          prediction: prediction,
          confidence: confidence,
          prob_normal: probs[0],
          prob_pneumonia: probs[1],
          report_text: inferenceError 
              ? techErrorMessage 
              : `AI analysis suggests a scan characteristic of ${prediction.toLowerCase()}.`,
          engine_status: inferenceError ? 'ERROR' : 'STABLE',
          processed_at: new Date().toISOString(),
        })
        .eq('id', resultId);
    }

    return new Response(
      JSON.stringify({ success: true, prediction, confidence }),
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
