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

      // 1. Upload to Supabase Storage (xray-images bucket)
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final filePath = "${user.id}/$fileName";
      
      final bytes = await imageFile.readAsBytes();
      await _supabase.storage.from('xray-images').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      // 2. Call Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'xray-inference',
        body: {
          'image_path': filePath,
          'patient_id': user.id,
        },
      );

      if (response.status != 200) {
        throw Exception("Edge Function error: ${response.data}");
      }

      final data = response.data as Map<String, dynamic>;
      final prediction = data['prediction'] as String;
      final confidence = (data['confidence'] as num).toDouble();
      final reportText = data['report_text'] as String;
      final probNormal = (data['normal_prob'] as num?)?.toDouble();
      final probPneumonia = (data['pneumonia_prob'] as num?)?.toDouble();

      return XRayResult(
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
        prediction: null,
        confidence: null,
        reportText: 'Analysis failed: ${e.toString()}',
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
