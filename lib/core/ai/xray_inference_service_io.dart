import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vitaguard_app/patient/data/patient_models.dart';

class XrayInferenceService {
  XrayInferenceService._();

  static final XrayInferenceService instance = XrayInferenceService._();

  final _supabase = Supabase.instance.client;

  bool get isReady => true; // Always ready as it's a network service

  Future<void> ensureLoaded() async {
    // No-op for network service
  }

  Future<XRayResult> analyze(File imageFile) async {
    final validation = await _validateImage(imageFile);
    if (validation != null) {
      return XRayResult(
        isValid: false,
        prediction: null,
        confidence: null,
        reportText: validation,
        imagePath: imageFile.path,
      );
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Unauthorized: No logged-in user found.");

      // 1. Upload to Supabase Storage
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final filePath = "${user.id}/$fileName";
      
      final bytes = await imageFile.readAsBytes();
      await _supabase.storage.from('xray-images').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      // 2. Pre-insert record to get a result_id
      final insertResponse = await _supabase
          .from('patient_xray_results')
          .insert({
            'patient_id': user.id,
            'prediction': 'PENDING',
            'image_path': filePath,
            'report_text': 'Analysis in progress...',
            'engine_status': 'INITIALIZING',
          })
          .select('id')
          .single();
      
      final resultId = insertResponse['id'] as String;

      // 3. Generate Public URL for the engine to fetch
      final imageUrl = _supabase.storage.from('xray-images').getPublicUrl(filePath);

      // 4. Call Supabase Edge Function with aligned keys
      final response = await _supabase.functions.invoke(
        'xray-inference',
        body: {
          'image_url': imageUrl,
          'result_id': resultId,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final prediction = (data['prediction'] as String?) ?? 'INDETERMINATE';
      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.5;
      
      // Look for technical error in the response JSON
      final rawError = data['error'] as String?;
      final reportText = (data['report_text'] as String?) ?? rawError ?? 'Engine failure. Technical correlation required.';
      
      final probNormal = (data['normal_prob'] as num?)?.toDouble() ?? 0.5;
      final probPneumonia = (data['pneumonia_prob'] as num?)?.toDouble() ?? 0.5;

      return XRayResult(
        id: resultId,
        isValid: true,
        prediction: prediction,
        confidence: confidence,
        reportText: reportText,
        imagePath: imageFile.path,
        probNormal: probNormal,
        probPneumonia: probPneumonia,
      );
    } catch (e) {
      debugPrint("X-ray analysis failed: $e");
      return XRayResult(
        isValid: false,
        prediction: 'INDETERMINATE',
        confidence: null,
        reportText: 'TECH_ERROR (LOCAL): ${e.toString()}',
        imagePath: imageFile.path,
      );
    }
  }

  Future<String?> _validateImage(File file) {
    return compute(_validateImageIsolate, file.path);
  }
}

Future<String?> _validateImageIsolate(String path) async {
  final ext = path.toLowerCase();
  if (!(ext.endsWith('.jpg') ||
      ext.endsWith('.jpeg') ||
      ext.endsWith('.png'))) {
    return 'Invalid file type. Please upload a JPEG or PNG image.';
  }

  final file = File(path);
  final size = await file.length();
  const maxBytes = 10 * 1024 * 1024;
  if (size > maxBytes) {
    return 'File too large. Maximum size is 10 MB.';
  }

  try {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return 'Invalid image file.';
    }
    if (decoded.width < 50 || decoded.height < 50) {
      return 'Image too small. Please upload a higher resolution X-ray.';
    }
    if (decoded.width > 10000 || decoded.height > 10000) {
      return 'Image dimensions too large.';
    }
  } catch (_) {
    return 'Invalid image file.';
  }

  return null;
}
