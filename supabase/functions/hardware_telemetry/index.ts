import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { corsHeaders } from "../_shared/cors.ts";

// This edge function is triggered by the ESP32 hardware device passing live telemetry payload over HTTP POST.
serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Security Check: To prevent unauthorized access when deployed with --no-verify-jwt
    // You should set HARDWARE_API_KEY in your Supabase project secrets
    const hardwareApiKey = Deno.env.get('HARDWARE_API_KEY');
    const requestKey = req.headers.get('X-Hardware-Key');

    if (hardwareApiKey && requestKey !== hardwareApiKey) {
      return new Response(JSON.stringify({ error: 'Unauthorized: Invalid Hardware Key' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      });
    }

    const body = await req.json();
    const { device_id, patient_id, vitals, motion, device_status, timestamp } = body;

    if (!device_id || !patient_id) {
      throw new Error("Missing required fields (device_id, patient_id)");
    }

    // Insert live vitals record
    const { error: vitalsError } = await supabaseClient
      .from('patient_live_vitals')
      .insert({
        patient_id: patient_id,
        device_id: device_id,
        bpm: vitals?.bpm,
        temperature: vitals?.temperature,
        spo2: vitals?.spo2,
        device_status: device_status,
        recorded_at: timestamp || new Date().toISOString()
      });

    if (vitalsError) {
      console.error("Vitals insert error:", vitalsError);
      throw vitalsError;
    }

    // Process edge cases to dispatch alerts
    const alerts = [];
    
    // Edge case 1: High heart rate
    if (vitals?.bpm > 130) {
      alerts.push({
        patient_id,
        alert_type: 'HIGH_HEART_RATE',
        alert_data: { bpm: vitals.bpm },
      });
    }

    // Edge case 2: Fall Detection via accelerometer Z-axis
    if (motion?.fall_detected === true || (motion?.acc_z && (motion.acc_z > 15 || motion.acc_z < 2))) {
      alerts.push({
        patient_id,
        alert_type: 'FALL_DETECTED',
        alert_data: { acc_z: motion?.acc_z ?? 0, fall_detected: motion?.fall_detected ?? true },
      });
    }

    // Dispatch potential alerts
    if (alerts.length > 0) {
      const { error: alertError } = await supabaseClient
        .from('medical_alerts')
        .insert(alerts);
        
      if (alertError) {
        console.error("Alerts insert error:", alertError);
        throw alertError;
      }
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
