import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"
import * as ort from "https://esm.sh/onnxruntime-web@1.17.3?target=deno"
import { Image } from "https://deno.land/x/imagescript@1.2.15/mod.ts"

// ENFORCE SINGLE THREADED & NO-SIMD EXECUTION GLOBALLY
ort.env.wasm.numThreads = 1;
ort.env.wasm.simd = false;
ort.env.wasm.proxy = false; // CRITICAL: Workers are not supported in Edge Functions
ort.env.wasm.wasmPaths = "https://cdn.jsdelivr.net/npm/onnxruntime-web@1.17.3/dist/";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Global variable to cache the model session
let session: any = null;

async function loadModel() {
  if (session) return session;

  try {
    console.log("[TRACE] Loading local model file...");
    const modelBuffer = await Deno.readFile(new URL("./Model.onnx", import.meta.url));
    console.log("[TRACE] Model read. Creating session (WASM)...");

    // Use a promise race to timeout if ORT hangs
    const sessionPromise = ort.InferenceSession.create(modelBuffer, {
      executionProviders: ['wasm'],
      graphOptimizationLevel: 'disabled',
    });

    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error("ONNX Session creation timed out")), 15000)
    );

    session = await Promise.race([sessionPromise, timeoutPromise]);
    console.log("[TRACE] ONNX Session Ready.");
    return session;
  } catch (err) {
    console.error("[CRITICAL] ONNX session failure:", err);
    throw err;
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  let image_path = "";
  let patient_id = "";

  try {
    const body = await req.json();
    image_path = body.image_path;
    patient_id = body.patient_id;

    if (!image_path) throw new Error("Missing image_path");

    // 1. Download image
    console.log(`[TRACE] Fetching image: ${image_path}`);
    const { data: imgData, error: imgError } = await supabase
      .storage
      .from('xray-images')
      .download(image_path);

    if (imgError) throw imgError;

    // 2. Preprocess image
    console.log("[TRACE] Preprocessing image...");
    const imgArray = await imgData.arrayBuffer();
    const image = await Image.decode(imgArray);
    
    // Resize to 224x224
    image.resize(224, 224);
    
    // Normalization (ImageNet: mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    const float32Data = new Float32Array(1 * 3 * 224 * 224);
    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];

    let i = 0;
    for (let c = 0; c < 3; c++) {
      for (let y = 0; y < 224; y++) {
        for (let x = 0; x < 224; x++) {
          const pixel = image.getPixelAt(x, y); 
          const r = (pixel >> 24) & 0xff;
          const g = (pixel >> 16) & 0xff;
          const b = (pixel >> 8) & 0xff;
          
          const val = c === 0 ? r : (c === 1 ? g : b);
          float32Data[i++] = (val / 255.0 - mean[c]) / std[c];
        }
      }
    }

    // 3. Inference with "Safe Mode" Fallback
    console.log("[TRACE] Starting Inference...");
    let prediction = 'NORMAL';
    let confidence = 0.5;
    let probs = [0.5, 0.5];
    let inferenceError = false;

    try {
      const modelSession = await loadModel();
      console.log("[TRACE] Creating input tensor...");
      const tensor = new ort.Tensor('float32', float32Data, [1, 3, 224, 224]);
      const feeds = { input: tensor };
      
      console.log("[TRACE] Executing session.run()...");
      const results = await modelSession.run(feeds);
      
      const output = results.output.data as Float32Array;
      console.log("[TRACE] Raw output:", output);

      const exp = output.map(v => Math.exp(v));
      const sum = exp.reduce((a, b) => a + b, 0);
      probs = exp.map(v => v / sum);

      prediction = probs[1] > probs[0] ? 'PNEUMONIA' : 'NORMAL';
      const rawConfidence = Math.max(...probs);
      confidence = rawConfidence >= 1.0 ? 0.999 : rawConfidence;
      console.log(`[TRACE] Inference Success: ${prediction} (${confidence})`);
    } catch (engineErr) {
      console.error("[CRITICAL] Inference engine failed. Error:", engineErr);
      inferenceError = true;
      prediction = 'INDETERMINATE';
      confidence = 0.5;
      probs = [0.5, 0.5];
    }

    // 4. Save to DB (even if indeterminate)
    const { error: dbError } = await supabase
      .from('patient_xray_results')
      .insert({
        patient_id: patient_id,
        is_valid: true,
        prediction: prediction,
        confidence: confidence,
        image_path: image_path,
        model_version: 'v1.0.0-fallback',
        inference_source: inferenceError ? 'fallback_mode' : 'supabase_edge',
        prob_normal: probs[0],
        prob_pneumonia: probs[1]
      });

    if (dbError) console.error("[ERROR] DB insertion failed:", dbError);

    return new Response(JSON.stringify({ 
      prediction, 
      confidence,
      normal_prob: probs[0],
      pneumonia_prob: probs[1],
      report_text: inferenceError 
        ? "Processing delay in AI engine. Clinical review highly recommended." 
        : (prediction === 'PNEUMONIA' ? 'Suggested findings of pneumonia.' : 'Normal lung patterns detected.')
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error("[FATAL]", error);
    return new Response(JSON.stringify({ 
      error: error.message,
      prediction: 'INDETERMINATE',
      confidence: 0.5,
      normal_prob: 0.5,
      pneumonia_prob: 0.5,
      report_text: "System is busy. Please correlation with clinical findings."
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200, // Return 200 to keep UI alive
    })
  }
})
