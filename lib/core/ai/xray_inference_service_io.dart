import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';

final _log = Logger();

/// Strictly apply softmax to logits. DenseNet exports raw logits, never probs.
List<double> _toProbs(double logit0, double logit1) {
  final m = math.max(logit0, logit1); // numerical stability
  final e0 = math.exp(logit0 - m);
  final e1 = math.exp(logit1 - m);
  final s = e0 + e1;
  return [e0 / s, e1 / s];
}

String _summarizeInputTensor(List<List<List<List<double>>>> t) {
  // t: [1][H][W][3]
  try {
    final h = t[0].length;
    final w = t[0][0].length;
    var n = 0;
    var rSum = 0.0, gSum = 0.0, bSum = 0.0;
    var rMin = double.infinity, gMin = double.infinity, bMin = double.infinity;
    var rMax = -double.infinity, gMax = -double.infinity, bMax = -double.infinity;
    var rgDiffSum = 0.0, rbDiffSum = 0.0, gbDiffSum = 0.0;

    for (final row in t[0]) {
      for (final px in row) {
        final r = px[0], g = px[1], b = px[2];
        n++;
        rSum += r; gSum += g; bSum += b;
        if (r < rMin) rMin = r;
        if (g < gMin) gMin = g;
        if (b < bMin) bMin = b;
        if (r > rMax) rMax = r;
        if (g > gMax) gMax = g;
        if (b > bMax) bMax = b;
        rgDiffSum += (r - g).abs();
        rbDiffSum += (r - b).abs();
        gbDiffSum += (g - b).abs();
      }
    }
    final rMean = rSum / n;
    final gMean = gSum / n;
    final bMean = bSum / n;
    final rg = rgDiffSum / n;
    final rb = rbDiffSum / n;
    final gb = gbDiffSum / n;
    return '[TFLITE] Input stats (normalized) ${h}x$w: '
        'R[min=${rMin.toStringAsFixed(3)}, max=${rMax.toStringAsFixed(3)}, mean=${rMean.toStringAsFixed(3)}] '
        'G[min=${gMin.toStringAsFixed(3)}, max=${gMax.toStringAsFixed(3)}, mean=${gMean.toStringAsFixed(3)}] '
        'B[min=${bMin.toStringAsFixed(3)}, max=${bMax.toStringAsFixed(3)}, mean=${bMean.toStringAsFixed(3)}] '
        'avg|R-G|=${rg.toStringAsFixed(4)} avg|R-B|=${rb.toStringAsFixed(4)} avg|G-B|=${gb.toStringAsFixed(4)}';
  } catch (_) {
    return '[TFLITE] Input stats unavailable';
  }
}

/// Model configuration — must match training pipeline exactly.
class _ModelConfig {
  static const String assetPath = 'assets/models/model.tflite';
  static const int inputSize = 320;
  static const String modelVersion = 'v1.0.0-tflite';
  static const bool debugTryPreprocessVariants = kDebugMode;

  /// Tuned thresholds for 3:1 imbalanced training
  static const double pneumoniaThreshold = 0.65;
  static const double inconclusiveLow = 0.40;

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
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (_isInitializing) {
        if (DateTime.now().isAfter(deadline)) {
          throw StateError('TFLite interpreter initialization timed out');
        }
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

      // Resize input tensor to 320x320 if it differs from _ModelConfig.inputSize
      final initialInShape = _interpreter!.getInputTensor(0).shape;
      if (initialInShape[1] != _ModelConfig.inputSize || initialInShape[2] != _ModelConfig.inputSize) {
        _log.i('[TFLITE] Resizing input tensor from $initialInShape to [1, ${_ModelConfig.inputSize}, ${_ModelConfig.inputSize}, 3]');
        _interpreter!.resizeInputTensor(0, [1, _ModelConfig.inputSize, _ModelConfig.inputSize, 3]);
        _interpreter!.allocateTensors();
      }

      // Log tensor shapes for diagnostics
      final inShape = _interpreter!.getInputTensor(0).shape;
      final outShape = _interpreter!.getOutputTensor(0).shape;
      _log.i('[TFLITE] Input shape: $inShape | Output shape: $outShape');

      // Verify HWC layout [1, H, W, 3]
      assert(
        inShape.length == 4 && inShape[3] == 3,
        'Model expects HWC [1,H,W,3] but got $inShape. If this is [1,3,H,W], the preprocess logic needs to be updated to CHW.',
      );
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
      _log.i(_summarizeInputTensor(inputTensor));

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
        final probs = _toProbs(z0, z1);
        probNormal = probs[0];
        probPneumonia = probs[1];
        _log.i('[TFLITE] Probs (after softmax): normal=$probNormal | pneumonia=$probPneumonia');
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
          final probs = _toProbs(flat[0], flat[1]);
          probNormal = probs[0];
          probPneumonia = probs[1];
        } else {
          probPneumonia = flat[0];
          probNormal = 1.0 - flat[0];
        }
      }

      // Optional: probe a few common medical-image mismatches to identify expected training preprocess.
      if (_ModelConfig.debugTryPreprocessVariants && outShape.length == 2 && outShape[1] == 2) {
        try {
          final variants = await compute(_preprocessVariantsForDebug, imageFile.path);
          for (final entry in variants.entries) {
            final output = [List.filled(2, 0.0)];
            _interpreter!.run(entry.value, output);
            final z0 = output[0][0];
            final z1 = output[0][1];
            final p = _toProbs(z0, z1);
            _log.i('[TFLITE][VARIANT] ${entry.key}: logits=[$z0, $z1] probs=[${p[0]}, ${p[1]}]');
          }
        } catch (e) {
          _log.w('[TFLITE][VARIANT] Debug variants failed: $e');
        }
      }

      // Tuned classification
      String prediction;
      if (probPneumonia >= _ModelConfig.pneumoniaThreshold) {
        prediction = 'PNEUMONIA';
      } else if (probPneumonia >= _ModelConfig.inconclusiveLow) {
        prediction = 'INCONCLUSIVE';
      } else {
        prediction = 'NORMAL';
      }

      final confidence = switch (prediction) {
        'PNEUMONIA' => probPneumonia,
        'NORMAL' => probNormal,
        _ => 1.0 - (probPneumonia - _ModelConfig.inconclusiveLow).abs(),
      };

      _log.i('[TFLITE] Result: $prediction | conf=${(confidence * 100).toStringAsFixed(1)}% | normal=${(probNormal * 100).toStringAsFixed(1)}% | pneumonia=${(probPneumonia * 100).toStringAsFixed(1)}%');

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

    if (prediction == 'INCONCLUSIVE') {
      return 'AI analysis is inconclusive for this image (certainty: $confPct%). '
          'The findings are borderline and require expert radiological review. '
          'P(Normal): $pNorm% | P(Pneumonia): $pPneu%.';
    }

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
      'processed_at': DateTime.now().toUtc().toIso8601String(),
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

/// Resize to _ModelConfig.inputSize and normalize for torchvision DenseNet121 (ImageNet stats, RGB).
/// Returns a [1, S, S, 3] nested list — the exact shape TFLite expects.
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

/// Debug-only: return a few plausible preprocessing variants to diagnose mismatch.
Map<String, List<List<List<List<double>>>>> _preprocessVariantsForDebug(String path) {
  final bytes = File(path).readAsBytesSync();
  img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) throw StateError('Cannot decode image at $path');

  decoded = img.copyResize(
    decoded,
    width: _ModelConfig.inputSize,
    height: _ModelConfig.inputSize,
    interpolation: img.Interpolation.linear,
  );

  List<List<List<List<double>>>> build({
    required bool grayscale3,
    required bool invert,
  }) {
    return [
      List.generate(_ModelConfig.inputSize, (y) {
        return List.generate(_ModelConfig.inputSize, (x) {
          final p = decoded!.getPixel(x, y);
          double r = p.r.toDouble();
          double g = p.g.toDouble();
          double b = p.b.toDouble();
          if (invert) {
            r = 255.0 - r;
            g = 255.0 - g;
            b = 255.0 - b;
          }
          if (grayscale3) {
            final gray = 0.299 * r + 0.587 * g + 0.114 * b;
            r = gray;
            g = gray;
            b = gray;
          }
          return [
            _ModelConfig.normalizeChannel(r, 0),
            _ModelConfig.normalizeChannel(g, 1),
            _ModelConfig.normalizeChannel(b, 2),
          ];
        });
      }),
    ];
  }

  return {
    'RGB': build(grayscale3: false, invert: false),
    'RGB_INVERT': build(grayscale3: false, invert: true),
    'GRAYx3': build(grayscale3: true, invert: false),
    'GRAYx3_INVERT': build(grayscale3: true, invert: true),
  };
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
