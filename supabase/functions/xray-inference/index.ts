import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"
import * as ort from "npm:onnxruntime-web@1.18.0"
import { Image } from "https://deno.land/x/imagescript@1.2.15/mod.ts"

// ENFORCE SINGLE THREADED EXECUTION GLOBALLY
// This must be set before any sessions are created
ort.env.wasm.numThreads = 1;
ort.env.wasm.proxy = false;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Global variable to cache the model session
let session: ort.InferenceSession | null = null;

async function loadModel(supabase: any) {
  if (session) return session;

  console.log("Downloading model from storage...");
  const { data, error } = await supabase
    .storage
    .from('ai-models')
    .download('Model.onnx');

  if (error) {
    console.error("Failed to download model:", error);
    throw new Error("Model download failed");
  }

  const modelBuffer = await data.arrayBuffer();
  console.log("Initializing ONNX session...");
  
  // Note: Deno doesn't support all WASM features of ort by default, 
  // but for simple models it works well.
  session = await ort.InferenceSession.create(modelBuffer, {
    executionProviders: ['wasm'],
    numThreads: 1,
  });
  
  return session;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { image_path, patient_id } = await req.json();

    if (!image_path) {
      return new Response(JSON.stringify({ error: 'Missing image_path' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Download image
    console.log(`Fetching image: ${image_path}`);
    const { data: imgData, error: imgError } = await supabase
      .storage
      .from('xray-images')
      .download(image_path);

    if (imgError) throw imgError;

    // 2. Preprocess image
    console.log("Preprocessing image...");
    const imgArray = await imgData.arrayBuffer();
    const image = await Image.decode(imgArray);
    
    // Resize to 224x224
    image.resize(224, 224);
    
    // Normalization (ImageNet: mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    const float32Data = new Float32Array(1 * 3 * 224 * 224);
    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];

    let i = 0;
    // ONNX expects NCHW format
    for (let c = 0; c < 3; c++) {
      for (let y = 0; y < 224; y++) {
        for (let x = 0; x < 224; x++) {
          const pixel = image.getPixelAt(x + 1, y + 1); 
          // Extract RGBA from uint32: [R(8), G(8), B(8), A(8)]
          const r = (pixel >> 24) & 0xff;
          const g = (pixel >> 16) & 0xff;
          const b = (pixel >> 8) & 0xff;
          
          const val = c === 0 ? r : (c === 1 ? g : b);
          float32Data[i++] = (val / 255.0 - mean[c]) / std[c];
        }
      }
    }

    // 3. Inference
    console.log("Running inference...");
    const modelSession = await loadModel(supabase);
    const tensor = new ort.Tensor('float32', float32Data, [1, 3, 224, 224]);
    const feeds = { input: tensor };
    const results = await modelSession.run(feeds);
    
    const output = results.output.data as Float32Array;
    console.log("Raw output:", output);

    // Apply Softmax to get confidence
    const exp = output.map(v => Math.exp(v));
    const sum = exp.reduce((a, b) => a + b, 0);
    const probs = exp.map(v => v / sum);

    const prediction = probs[1] > probs[0] ? 'PNEUMONIA' : 'NORMAL';
    
    // Safety: No 100% confidence in Medical AI
    const rawConfidence = Math.max(...probs);
    const confidence = rawConfidence >= 1.0 ? 0.999 : rawConfidence;

    // 4. Save to DB
    console.log(`Saving result: ${prediction} (${confidence})`);
    const { error: dbError } = await supabase
      .from('patient_xray_results')
      .insert({
        patient_id: patient_id,
        is_valid: true,
        prediction: prediction,
        confidence: confidence,
        image_path: image_path,
        model_version: 'v1.0.0',
        inference_source: 'supabase_edge',
        prob_normal: probs[0],
        prob_pneumonia: probs[1]
      });

    if (dbError) throw dbError;

    return new Response(JSON.stringify({ 
      prediction, 
      confidence,
      normal_prob: probs[0],
      pneumonia_prob: probs[1],
      report_text: prediction === 'PNEUMONIA' ? 'Suggested findings of pneumonia.' : 'Normal lung patterns detected.'
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
