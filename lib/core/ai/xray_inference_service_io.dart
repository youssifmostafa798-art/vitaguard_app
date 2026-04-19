import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';

final _log = Logger();

/// Map two outputs to **probabilities** for UI: if values already look like probs, keep; else softmax(logits).
List<double> _twoClassProbs(double a, double b) {
  const eps = 1e-5;
  if (a >= -eps && b >= -eps && a <= 1.0 + eps && b <= 1.0 + eps) {
    final s = a + b;
    if (s > 0.97 && s < 1.03) {
      return [a, b];
    }
  }
  final m = a > b ? a : b;
  final ea = math.exp(a - m);
  final eb = math.exp(b - m);
  final sum = ea + eb;
  return [ea / sum, eb / sum];
}

List<double> _finiteMinMax(List<double> xs) {
  var min = double.infinity;
  var max = -double.infinity;
  for (final v in xs) {
    if (!v.isFinite) continue;
    if (v < min) min = v;
    if (v > max) max = v;
  }
  if (min == double.infinity) min = double.nan;
  if (max == -double.infinity) max = double.nan;
  return [min, max];
}

/// Model configuration — must match training pipeline exactly.
class _ModelConfig {
  static const String assetPath = 'assets/models/model.tflite';
  static const int inputSize = 224;
  static const String modelVersion = 'v1.0.0-tflite';

  /// Torchvision DenseNet121 / Fastai-style: `pixel/255` then ImageNet mean/std (RGB).
  /// See `scripts/convert_to_onnx.py` (DenseNet121 backbone). Do not use EfficientNet [-1,1] here.
  static const List<double> _imagenetMean = [0.485, 0.456, 0.406];
  static const List<double> _imagenetStd = [0.229, 0.224, 0.225];

  static double normalizeChannel(double channel0to255, int rgbIndex) {
    final x = channel0to255 / 255.0;
    return (x - _imagenetMean[rgbIndex]) / _imagenetStd[rgbIndex];
  }
}

/// On-device TFLite X-ray inference service.
///
/// Uses a regular [Interpreter] (not IsolateInterpreter) because the heavy
/// preprocessing already runs in a background isolate via [compute].
/// The interpreter is lazily loaded and cached for the entire app session.
class XrayInferenceService {
  XrayInferenceService._();
  static final XrayInferenceService instance = XrayInferenceService._();

  Interpreter? _interpreter;
  bool _isInitializing = false;

  bool get isReady => _interpreter != null;

  final _supabase = Supabase.instance.client;

  /// Lazily loads and caches the TFLite interpreter. Safe to call multiple times.
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
      Interpreter? interp;

      // --- Attempt 1: GPU Delegate ---
      try {
        final opts = InterpreterOptions()..addDelegate(GpuDelegateV2());
        interp = await Interpreter.fromAsset(_ModelConfig.assetPath, options: opts);
        _log.i('[TFLITE] Loaded with GPU delegate.');
      } catch (gpuErr) {
        _log.w('[TFLITE] GPU delegate unavailable: $gpuErr');

        // --- Attempt 2: CPU only ---
        try {
          interp = await Interpreter.fromAsset(_ModelConfig.assetPath);
          _log.i('[TFLITE] Loaded on CPU.');
        } catch (cpuErr) {
          _log.e('[TFLITE] CPU load also failed: $cpuErr');
          rethrow;
        }
      }

      _interpreter = interp;

      // Log tensor shapes for diagnostics
      final inShape = _interpreter!.getInputTensor(0).shape;
      final outShape = _interpreter!.getOutputTensor(0).shape;
      _log.i('[TFLITE] Input shape: $inShape | Output shape: $outShape');
    } finally {
      _isInitializing = false;
    }
  }

  /// Main entry point: validate → preprocess → infer → async log.
  Future<XRayResult> analyze(File imageFile) async {
    // 1. Validate
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
      // 2. Load model
      await ensureLoaded();
      if (_interpreter == null) {
        throw StateError('TFLite interpreter failed to initialize.');
      }

      // 3. Preprocess in background isolate — [1, 224, 224, 3] float32
      final sw = Stopwatch()..start();
      final inputTensor = await compute(_preprocessImage, imageFile.path);
      _log.d('[TFLITE] Preprocessing: ${sw.elapsedMilliseconds}ms');
      _log.d('[TFLITE] Model version: ${_ModelConfig.modelVersion}');

      // Lightweight input sanity stats (helps detect “all-black”, wrong decode, or stuck preprocess).
      try {
        final flatR = <double>[];
        final flatG = <double>[];
        final flatB = <double>[];
        for (final row in inputTensor[0]) {
          for (final px in row) {
            flatR.add(px[0]);
            flatG.add(px[1]);
            flatB.add(px[2]);
          }
        }
        double mean(List<double> xs) => xs.reduce((a, b) => a + b) / xs.length;
        final rmm = _finiteMinMax(flatR);
        final gmm = _finiteMinMax(flatG);
        final bmm = _finiteMinMax(flatB);
        _log.d(
          '[TFLITE] Input stats (normalized): '
          'R[min=${rmm[0].toStringAsFixed(3)}, max=${rmm[1].toStringAsFixed(3)}, mean=${mean(flatR).toStringAsFixed(3)}] '
          'G[min=${gmm[0].toStringAsFixed(3)}, max=${gmm[1].toStringAsFixed(3)}, mean=${mean(flatG).toStringAsFixed(3)}] '
          'B[min=${bmm[0].toStringAsFixed(3)}, max=${bmm[1].toStringAsFixed(3)}, mean=${mean(flatB).toStringAsFixed(3)}]',
        );
      } catch (_) {
        // best-effort stats only
      }

      // 4. Detect output shape and allocate accordingly
      final outShape = _interpreter!.getOutputTensor(0).shape;
      _log.d('[TFLITE] Runtime output shape: $outShape');

      double probNormal;
      double probPneumonia;

      if (outShape.length == 2 && outShape[1] == 2) {
        // ── Two-class head: exported as logits (CrossEntropy) in almost all TFLite DenseNet exports ──
        final output = [List.filled(2, 0.0)];
        _interpreter!.run(inputTensor, output);
        sw.stop();
        final z0 = output[0][0];
        final z1 = output[0][1];
        _log.i('[TFLITE] Inference [1,2] logits: ${sw.elapsedMilliseconds}ms | raw=[$z0, $z1]');
        final probs = _twoClassProbs(z0, z1);
        probNormal = probs[0];
        probPneumonia = probs[1];
        _log.i('[TFLITE] Probs (after softmax if logits): normal=$probNormal | pneumonia=$probPneumonia');
      } else if (outShape.length == 2 && outShape[1] == 1) {
        // ── Sigmoid output: [1, 1] → probability of PNEUMONIA ──
        final output = [List.filled(1, 0.0)];
        _interpreter!.run(inputTensor, output);
        sw.stop();
        final sigmoid = output[0][0];
        _log.i('[TFLITE] Inference (sigmoid[1,1]): ${sw.elapsedMilliseconds}ms | raw=$sigmoid');
        probPneumonia = sigmoid;
        probNormal = 1.0 - sigmoid;
      } else {
        // ── Unknown shape — try flat list ──
        _log.w('[TFLITE] Unknown output shape $outShape, trying flat output...');
        final flat = List.filled(outShape.reduce((a, b) => a * b), 0.0);
        _interpreter!.run(inputTensor, flat);
        sw.stop();
        _log.i('[TFLITE] Flat inference: ${sw.elapsedMilliseconds}ms | raw=$flat');
        if (flat.length >= 2) {
          final probs = _twoClassProbs(flat[0], flat[1]);
          probNormal = probs[0];
          probPneumonia = probs[1];
        } else {
          probPneumonia = flat[0];
          probNormal = 1.0 - flat[0];
        }
      }

      final prediction = probPneumonia > probNormal ? 'PNEUMONIA' : 'NORMAL';
      final confidence = prediction == 'PNEUMONIA' ? probPneumonia : probNormal;

      _log.i('[TFLITE] Result: $prediction | conf=${(confidence*100).toStringAsFixed(1)}% | normal=${(probNormal*100).toStringAsFixed(1)}% | pneumonia=${(probPneumonia*100).toStringAsFixed(1)}%');

      final reportText = _buildReport(prediction, confidence, probNormal, probPneumonia);

      final result = XRayResult(
        isValid: true,
        prediction: prediction,
        confidence: confidence,
        reportText: reportText,
        imagePath: imageFile.path,
        probNormal: probNormal,
        probPneumonia: probPneumonia,
      );

      // 5. Background Supabase log — never blocks the user
      _logToSupabase(imageFile, result).catchError(
        (e) => _log.w('[SUPABASE] Background log non-critical error: $e'),
      );

      return result;
    } catch (e, st) {
      _log.e('[TFLITE] Inference error', error: e, stackTrace: st);
      return XRayResult(
        isValid: false,
        prediction: 'INDETERMINATE',
        confidence: null,
        reportText: 'On-device analysis failed. Please retry. ($e)',
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
    }
    return 'AI analysis indicates no significant radiological findings '
        'consistent with pneumonia (confidence: $confPct%). '
        'Clinical correlation advised. '
        'P(Normal): $pNorm% | P(Pneumonia): $pPneu%.';
  }

  Future<void> _logToSupabase(File imageFile, XRayResult result) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final bytes = await imageFile.readAsBytes();
    final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _supabase.storage.from('xray-images').uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );

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

    _log.i('[SUPABASE] Prediction logged.');
  }

  Future<String?> _validateImage(File file) {
    return compute(_validateImageIsolate, file.path);
  }
}

// ---------------------------------------------------------------------------
// Top-level isolate functions
// ---------------------------------------------------------------------------

/// Resize to 224×224 and normalize for torchvision DenseNet121 (ImageNet stats, RGB, NHWC).
/// Returns a [1, 224, 224, 3] nested list — the exact shape TFLite expects.
List<List<List<List<double>>>> _preprocessImage(String path) {
  final bytes = File(path).readAsBytesSync();
  img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) throw StateError('Cannot decode image at $path');

  decoded = img.copyResize(
    decoded,
    width: _ModelConfig.inputSize,
    height: _ModelConfig.inputSize,
    interpolation: img.Interpolation.linear,
  );

  return [
    List.generate(_ModelConfig.inputSize, (y) {
      return List.generate(_ModelConfig.inputSize, (x) {
        final pixel = decoded!.getPixel(x, y);
        return [
          _ModelConfig.normalizeChannel(pixel.r.toDouble(), 0),
          _ModelConfig.normalizeChannel(pixel.g.toDouble(), 1),
          _ModelConfig.normalizeChannel(pixel.b.toDouble(), 2),
        ];
      });
    }),
  ];
}

/// Validates file type, size, and image integrity.
Future<String?> _validateImageIsolate(String path) async {
  final ext = path.toLowerCase();
  if (!(ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png'))) {
    return 'Invalid file type. Please upload a JPEG or PNG image.';
  }
  final size = await File(path).length();
  if (size > 10 * 1024 * 1024) return 'File too large. Maximum size is 10 MB.';
  try {
    final decoded = img.decodeImage(File(path).readAsBytesSync());
    if (decoded == null) return 'Invalid or corrupted image file.';
    if (decoded.width < 50 || decoded.height < 50) {
      return 'Image resolution too low. Please upload a higher quality X-ray.';
    }
  } catch (_) {
    return 'Cannot read image file.';
  }
  return null;
}
