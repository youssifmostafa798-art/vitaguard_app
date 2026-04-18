import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';

final _log = Logger();

/// Model configuration — must match training pipeline exactly.
class _ModelConfig {
  static const String assetPath = 'assets/models/model.tflite';
  static const int inputSize = 224;
  static const String modelVersion = 'v1.0.0-tflite';

  /// EfficientNet preprocessing: scale [0,255] → [-1, 1]
  static double normalize(double pixel) => (pixel / 127.5) - 1.0;
}

/// On-device TFLite X-ray inference service.
///
/// Architecture: On-device PRIMARY (< 150 ms target) with async Supabase
/// background logging. The interpreter is lazily loaded and cached for the
/// app lifetime — no reloading on every inference call.
class XrayInferenceService {
  XrayInferenceService._();
  static final XrayInferenceService instance = XrayInferenceService._();

  // IsolateInterpreter wraps the underlying Interpreter and runs
  // inference on a separate isolate automatically.
  IsolateInterpreter? _interpreter;
  bool _isInitializing = false;

  bool get isReady => _interpreter != null;

  final _supabase = Supabase.instance.client;

  /// Ensures the TFLite interpreter is loaded. Safe to call multiple times.
  Future<void> ensureLoaded() async {
    if (_interpreter != null) return;
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;
    try {
      // Try GPU delegate first; fall back to CPU on failure.
      try {
        final options = InterpreterOptions()..addDelegate(GpuDelegateV2());
        final base = await Interpreter.fromAsset(
          _ModelConfig.assetPath,
          options: options,
        );
        _interpreter = await IsolateInterpreter.create(address: base.address);
        _log.i('[TFLITE] Interpreter loaded with GPU delegate.');
      } catch (gpuErr) {
        _log.w('[TFLITE] GPU delegate failed ($gpuErr). Falling back to CPU.');
        final base = await Interpreter.fromAsset(_ModelConfig.assetPath);
        _interpreter = await IsolateInterpreter.create(address: base.address);
        _log.i('[TFLITE] Interpreter loaded on CPU.');
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// Main entry point: validate → preprocess → infer → log.
  Future<XRayResult> analyze(File imageFile) async {
    // --- 1. Validate image ---
    final validationError = await _validateImage(imageFile);
    if (validationError != null) {
      return XRayResult(
        isValid: false,
        prediction: null,
        confidence: null,
        reportText: validationError,
        imagePath: imageFile.path,
      );
    }

    try {
      // --- 2. Ensure model is loaded ---
      await ensureLoaded();
      if (_interpreter == null) {
        throw StateError('TFLite interpreter failed to initialize.');
      }

      // --- 3. Preprocess image in background isolate ---
      final sw = Stopwatch()..start();
      final inputTensor = await compute(_preprocessImage, imageFile.path);
      _log.d('[TFLITE] Preprocessing: ${sw.elapsedMilliseconds}ms');

      // --- 4. Run inference ---
      // Output shape: [1, 2] → [NORMAL, PNEUMONIA] probabilities
      final output = List.filled(2, 0.0).reshape([1, 2]);
      await _interpreter!.run(inputTensor, output);
      sw.stop();
      _log.i('[TFLITE] Inference complete in ${sw.elapsedMilliseconds}ms');

      final probNormal = (output[0][0] as double);
      final probPneumonia = (output[0][1] as double);

      final prediction = probPneumonia > probNormal ? 'PNEUMONIA' : 'NORMAL';
      final confidence = prediction == 'PNEUMONIA' ? probPneumonia : probNormal;

      final reportText =
          _buildReport(prediction, confidence, probNormal, probPneumonia);

      final result = XRayResult(
        isValid: true,
        prediction: prediction,
        confidence: confidence,
        reportText: reportText,
        imagePath: imageFile.path,
        probNormal: probNormal,
        probPneumonia: probPneumonia,
      );

      // --- 5. Background upload & log (fire-and-forget) ---
      _logToSupabase(imageFile, result).catchError(
        (e) => _log.w('[SUPABASE] Background log non-critical error: $e'),
      );

      return result;
    } catch (e) {
      _log.e('[TFLITE] Inference error: $e');
      return XRayResult(
        isValid: false,
        prediction: 'INDETERMINATE',
        confidence: null,
        reportText: 'On-device analysis failed. Please retry.',
        imagePath: imageFile.path,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _buildReport(
    String prediction,
    double confidence,
    double probNormal,
    double probPneumonia,
  ) {
    final confPct = (confidence * 100).toStringAsFixed(1);
    final pNorm = (probNormal * 100).toStringAsFixed(1);
    final pPneu = (probPneumonia * 100).toStringAsFixed(1);
    if (prediction == 'PNEUMONIA') {
      return 'AI analysis indicates findings consistent with pneumonia '
          '(confidence: $confPct%). '
          'Radiological correlation and clinical assessment are recommended. '
          'P(Normal): $pNorm% | P(Pneumonia): $pPneu%.';
    } else {
      return 'AI analysis indicates no significant radiological findings '
          'consistent with pneumonia (confidence: $confPct%). '
          'Clinical correlation advised. '
          'P(Normal): $pNorm% | P(Pneumonia): $pPneu%.';
    }
  }

  Future<void> _logToSupabase(File imageFile, XRayResult result) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Upload compressed image
    final bytes = await imageFile.readAsBytes();
    final fileName =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _supabase.storage
        .from('xray-images')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    // Log prediction to DB
    await _supabase.from('patient_xray_results').insert({
      'patient_id': user.id,
      'image_path': fileName,
      'prediction': result.prediction,
      'confidence': result.confidence,
      'prob_normal': result.probNormal,
      'prob_pneumonia': result.probPneumonia,
      'report_text': result.reportText,
      'engine_status': 'STABLE',
      'inference_mode': 'on-device',
      'model_version': _ModelConfig.modelVersion,
      'processed_at': DateTime.now().toIso8601String(),
    });

    _log.i('[SUPABASE] Prediction logged successfully.');
  }

  Future<String?> _validateImage(File file) {
    return compute(_validateImageIsolate, file.path);
  }
}

// ---------------------------------------------------------------------------
// Top-level isolate functions (must be top-level, not class methods)
// ---------------------------------------------------------------------------

/// Preprocessing pipeline: resize → normalize → reshape to [1, 224, 224, 3].
/// Runs in background isolate via [compute] to keep UI at 60fps.
List<List<List<List<double>>>> _preprocessImage(String path) {
  final bytes = File(path).readAsBytesSync();
  img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) throw StateError('Cannot decode image at $path');

  // Resize to 224x224 (model input size)
  decoded = img.copyResize(
    decoded,
    width: _ModelConfig.inputSize,
    height: _ModelConfig.inputSize,
  );

  // Build [1, 224, 224, 3] float32 tensor with EfficientNet normalization
  return [
    List.generate(_ModelConfig.inputSize, (y) {
      return List.generate(_ModelConfig.inputSize, (x) {
        final pixel = decoded!.getPixel(x, y);
        return [
          _ModelConfig.normalize(pixel.r.toDouble()),
          _ModelConfig.normalize(pixel.g.toDouble()),
          _ModelConfig.normalize(pixel.b.toDouble()),
        ];
      });
    }),
  ];
}

/// Image quality validation gate — runs in background isolate.
Future<String?> _validateImageIsolate(String path) async {
  final ext = path.toLowerCase();
  if (!(ext.endsWith('.jpg') ||
      ext.endsWith('.jpeg') ||
      ext.endsWith('.png'))) {
    return 'Invalid file type. Please upload a JPEG or PNG image.';
  }

  final size = await File(path).length();
  if (size > 10 * 1024 * 1024) {
    return 'File too large. Maximum size is 10 MB.';
  }

  try {
    final decoded = img.decodeImage(File(path).readAsBytesSync());
    if (decoded == null) return 'Invalid or corrupted image file.';
    if (decoded.width < 50 || decoded.height < 50) {
      return 'Image resolution too low. Please upload a higher quality X-ray.';
    }
  } catch (_) {
    return 'Cannot read image file.';
  }

  return null; // valid
}
