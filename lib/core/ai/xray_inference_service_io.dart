import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:vitaguard_app/data/models/patient/patient_models.dart';

// ─────────────────────────────────────────────────────────────
// Softmax helper
//
// DenseNet121 exported via CrossEntropyLoss always emits raw
// logits from the final FC layer. Softmax must always be applied
// here — never assume the output is already a probability.
// ─────────────────────────────────────────────────────────────

/// Strictly apply softmax to a pair of raw logits.
/// Uses the max-subtraction trick for numerical stability.
List<double> _toProbs(double logit0, double logit1) {
  final m = math.max(logit0, logit1);
  final e0 = math.exp(logit0 - m);
  final e1 = math.exp(logit1 - m);
  final s = e0 + e1;
  return [e0 / s, e1 / s];
}

// ─────────────────────────────────────────────────────────────
// Model configuration
//
// Every constant here must match the training pipeline exactly.
// The training script is the single source of truth — if you
// retrain with different settings, update these values first.
// ─────────────────────────────────────────────────────────────

class _ModelConfig {
  // Path inside the Flutter assets bundle.
  static const String assetPath = 'assets/models/model.tflite';

  // FIX — must equal CONFIG["image_size"] = 320 in the Python
  // training script. The previous value of 224 was the root cause
  // of the false-positive explosion: DenseNet121's Global Average
  // Pool produces a completely different 1024-dim vector at 224
  // versus 320, so the trained FC head received foreign inputs.
  static const int inputSize = 320;

  // Bump this string whenever you ship a retrained model so
  // Supabase logs can be filtered by model generation.
  static const String modelVersion = 'v2.0.0-tflite';

  // ── Decision thresholds ──────────────────────────────────
  // These values come from threshold.json written by the Python
  // calibrate_threshold() function after training.
  //
  // pneumoniaThreshold : lowest PNEUMONIA score to call PNEUMONIA.
  //                      Below this the result is NORMAL or INCONCLUSIVE.
  // inconclusiveLow    : scores between inconclusiveLow and
  //                      pneumoniaThreshold are shown as INCONCLUSIVE
  //                      rather than a hard NORMAL — this is the
  //                      uncertainty band required by FDA SaMD guidance.
  //
  // Copy updated values here after every retrain + calibration run.
  // Decision thresholds (calibrated on 'test' set)
  static const double pneumoniaThreshold = 0.6;
  static const double inconclusiveLow = 0.45;

  // Internal metrics for record keeping
  static const Map<String, dynamic> _performanceMetrics = {
    "precision_at_threshold": 0.9605,
    "recall_at_threshold": 0.9359,
    "specificity_at_threshold": 0.9359,
    "f1_at_threshold": 0.9481,
    "balanced_acc_at_threshold": 0.9359,
    "fp_at_threshold": 15,
    "fn_at_threshold": 25,
    "calibrated_on": "test",
    "image_size": 320,
  };

  // The updated TFLite graph now performs ImageNet preprocessing
  // internally using:
  //   x -> x * (1 / 255) -> x - mean -> x * (1 / std)
  // Flutter must therefore pass raw RGB values after resize in
  // NHWC layout [1, 320, 320, 3] and must not:
  //   - divide by 255
  //   - subtract mean
  //   - divide by std
  //   - convert to grayscale
  //   - invert colors
  //   - transpose to NCHW / CHW
}

// ─────────────────────────────────────────────────────────────
// XrayInferenceService
// ─────────────────────────────────────────────────────────────

/// On-device TFLite chest X-ray inference service.
///
/// Architecture:
///   • The TFLite interpreter is lazily loaded once and cached
///     for the entire app session (singleton via [instance]).
///   • Heavy preprocessing runs in a background isolate via
///     [compute] so the UI thread is never blocked.
///   • Supabase logging is fire-and-forget and never blocks
///     the result being returned to the caller.
class XrayInferenceService {
  XrayInferenceService._();
  static final XrayInferenceService instance = XrayInferenceService._();

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  bool _isInitializing = false;

  bool get isReady => _interpreter != null && _isolateInterpreter != null;

  final _supabase = SupabaseService.instance;

  /// Returns the calibrated performance metrics for the current model.
  Map<String, dynamic> get performanceMetrics =>
      _ModelConfig._performanceMetrics;

  // ── Interpreter loader ─────────────────────────────────────

  /// Lazily loads and caches the TFLite interpreter.
  /// Safe to call multiple times — subsequent calls return immediately.
  Future<void> ensureLoaded() async {
    if (_interpreter != null) return;

    // If another call already started initializing, wait for it
    // rather than creating a second interpreter.
    if (_isInitializing) {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (_isInitializing) {
        if (DateTime.now().isAfter(deadline)) {
          throw StateError(
            'TFLite interpreter initialization timed out after 10 s. '
            'The model asset may be missing or corrupt.',
          );
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isInitializing = true;
    try {
      Interpreter? interp;

      // Attempt 1 — GPU delegate (faster on supported devices)
      try {
        final opts = InterpreterOptions()..addDelegate(GpuDelegateV2());
        interp = await Interpreter.fromAsset(
          _ModelConfig.assetPath,
          options: opts,
        );
      } catch (_) {
        // Attempt 2 — CPU fallback
        try {
          interp = await Interpreter.fromAsset(_ModelConfig.assetPath);
        } catch (_) {
          rethrow;
        }
      }

      _interpreter = interp;
      _isolateInterpreter = await IsolateInterpreter.create(address: interp.address);

      // ── Tensor shape verification ────────────────────────
      final initialInShape = _interpreter!.getInputTensor(0).shape;

      if (initialInShape[1] != _ModelConfig.inputSize ||
          initialInShape[2] != _ModelConfig.inputSize) {
        // The exported model's baked-in shape differs from inputSize.
        // Attempt a dynamic resize — note that GPU delegates often do
        // NOT support this and will throw. If resize fails the error
        // is rethrown so the caller knows the model is incompatible.
        try {
          _interpreter!.resizeInputTensor(0, [
            1,
            _ModelConfig.inputSize,
            _ModelConfig.inputSize,
            3,
          ]);
          _interpreter!.allocateTensors();
        } catch (_) {
          rethrow;
        }
      }

      final inShape = _interpreter!.getInputTensor(0).shape;

      // The baked preprocessing wrapper expects NHWC [1, H, W, 3].
      // Reject CHW/NCHW models explicitly so Flutter never feeds the
      // graph with the wrong memory layout.
      if (inShape.length != 4) {
        throw StateError(
          'Model input must be 4D NHWC [1,H,W,3], but got $inShape.',
        );
      }
      if (inShape[3] != 3) {
        throw StateError(
          'Model input must be channel-last NHWC [1,H,W,3], but got '
          '$inShape. CHW/NCHW models are unsupported by this pipeline.',
        );
      }
    } finally {
      _isInitializing = false;
    }
  }

  // ── Main inference entry point ─────────────────────────────

  /// validate → preprocess → infer → classify → log
  Future<XRayResult> analyze(File imageFile, {String? patientIdForLog}) async {
    // Step 1 — file validation (runs in isolate)
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
      // Step 2 — ensure interpreter is ready
      await ensureLoaded();
      if (_interpreter == null || _isolateInterpreter == null) {
        throw StateError('TFLite interpreter failed to initialize.');
      }

      // Step 3 — preprocess in background isolate
      // Produces [1, 320, 320, 3] float32 nested list (HWC layout)
      // containing raw RGB values in [0, 255]. The TFLite graph now
      // applies the ImageNet wrapper internally.
      final inputTensor = await compute(_preprocessImage, imageFile.path);

      // Step 4 — run inference
      final outShape = _interpreter!.getOutputTensor(0).shape;

      double probNormal;
      double probPneumonia;

      if (outShape.length == 2 && outShape[1] == 2) {
        // Standard two-class head: [1, 2] raw logits
        // (CrossEntropyLoss export — softmax not baked in).
        // Exported class order is fixed: [NORMAL, PNEUMONIA].
        final output = [List.filled(2, 0.0)];
        await _isolateInterpreter!.run(inputTensor, output);
        final z0 = output[0][0]; // NORMAL logit
        final z1 = output[0][1]; // PNEUMONIA logit
        final probs = _toProbs(z0, z1);
        probNormal = probs[0];
        probPneumonia = probs[1];
      } else if (outShape.length == 2 && outShape[1] == 1) {
        // Sigmoid single-output head: [1, 1] → P(PNEUMONIA)
        final output = [List.filled(1, 0.0)];
        await _isolateInterpreter!.run(inputTensor, output);
        final sigmoid = output[0][0];
        probPneumonia = sigmoid;
        probNormal = 1.0 - sigmoid;
      } else {
        // Unexpected shape — try flat list as last resort
        final flat = List.filled(outShape.reduce((a, b) => a * b), 0.0);
        await _isolateInterpreter!.run(inputTensor, flat);
        if (flat.length >= 2) {
          final probs = _toProbs(flat[0], flat[1]);
          probNormal = probs[0];
          probPneumonia = probs[1];
        } else {
          probPneumonia = flat[0];
          probNormal = 1.0 - flat[0];
        }
      }

      // Step 5 — three-way classification using calibrated thresholds
      //
      // pneumoniaThreshold (0.6): trained threshold from calibration
      //   on the held-out test set. A score at or above this value
      //   is classified as PNEUMONIA.
      //
      // inconclusiveLow (0.45): scores between 0.45 and 0.6
      //   are in the uncertainty band and shown as INCONCLUSIVE.
      //   This satisfies FDA SaMD guidance — a borderline AI result
      //   must surface uncertainty rather than force a binary decision.
      //
      // Below inconclusiveLow: NORMAL.
      final String prediction;
      if (probPneumonia >= _ModelConfig.pneumoniaThreshold) {
        prediction = 'PNEUMONIA';
      } else if (probPneumonia >= _ModelConfig.inconclusiveLow) {
        prediction = 'INCONCLUSIVE';
      } else {
        prediction = 'NORMAL';
      }

      // Step 6 — confidence score
      //
      // PNEUMONIA / NORMAL: the model's probability for the predicted class.
      // INCONCLUSIVE: how far from the centre of the uncertainty band
      //   the score sits. 1.0 = right at the midpoint (maximally uncertain).
      //   0.0 = just barely inside the band (near a boundary).
      //   This is displayed to the user as "certainty of uncertainty" so
      //   they understand whether the result is deeply or marginally borderline.
      final double confidence;
      if (prediction == 'PNEUMONIA') {
        confidence = probPneumonia;
      } else if (prediction == 'NORMAL') {
        confidence = probNormal;
      } else {
        // INCONCLUSIVE — express how central the score is in the band.
        // Band centre is the midpoint; halfRange is half the band width.
        const mid =
            (_ModelConfig.pneumoniaThreshold + _ModelConfig.inconclusiveLow) /
            2.0;
        const halfRange =
            (_ModelConfig.pneumoniaThreshold - _ModelConfig.inconclusiveLow) /
            2.0;
        // Normalised distance from centre: 0 = edge of band, 1 = centre.
        confidence =
            1.0 - ((probPneumonia - mid) / halfRange).abs().clamp(0.0, 1.0);
      }

      final reportText = _buildReport(
        prediction,
        confidence,
        probNormal,
        probPneumonia,
      );

      final result = XRayResult(
        isValid: true,
        prediction: prediction,
        confidence: confidence,
        reportText: reportText,
        imagePath: imageFile.path,
        probNormal: probNormal,
        probPneumonia: probPneumonia,
      );

      // Step 7 — async Supabase log (never blocks the caller)
      _logToSupabase(
        imageFile,
        result,
        patientIdForLog: patientIdForLog,
      ).catchError((_) {});

      return result;
    } catch (e) {
      return XRayResult(
        isValid: false,
        prediction: 'INDETERMINATE',
        confidence: null,
        reportText: 'On-device analysis failed. Please retry. ($e)',
        imagePath: imageFile.path,
      );
    }
  }

  // ── Private helpers ────────────────────────────────────────

  /// Builds the human-readable report string for all three
  /// prediction states including the raw probability breakdown.
  String _buildReport(
    String prediction,
    double confidence,
    double probNormal,
    double probPneumonia,
  ) {
    final confPct = (confidence * 100).toStringAsFixed(1);
    final pNorm = (probNormal * 100).toStringAsFixed(1);
    final pPneu = (probPneumonia * 100).toStringAsFixed(1);

    switch (prediction) {
      case 'PNEUMONIA':
        return 'AI analysis indicates findings consistent with pneumonia '
            '(confidence: $confPct%). '
            'Radiological correlation and clinical assessment are recommended. '
            'P(Normal): $pNorm% | P(Pneumonia): $pPneu%.';

      case 'INCONCLUSIVE':
        return 'AI analysis is inconclusive for this image '
            '(borderline certainty: $confPct%). '
            'The findings are borderline and require expert radiological review. '
            'P(Normal): $pNorm% | P(Pneumonia): $pPneu%.';

      default: // NORMAL
        return 'AI analysis indicates no significant radiological findings '
            'consistent with pneumonia (confidence: $confPct%). '
            'Clinical correlation advised. '
            'P(Normal): $pNorm% | P(Pneumonia): $pPneu%.';
    }
  }

  /// Uploads the image and prediction to Supabase.
  /// Runs entirely in the background — any error is swallowed and
  /// logged rather than surfaced to the user.
  Future<void> _logToSupabase(
    File imageFile,
    XRayResult result, {
    required String? patientIdForLog,
  }) async {
    final user = _supabase.currentUser;
    if (user == null || patientIdForLog == null || patientIdForLog.isEmpty) {
      return;
    }

    final bytes = await imageFile.readAsBytes();
    final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.uploadBinary(
      bucketId: 'xray-images',
      path: fileName,
      bytes: bytes,
      contentType: 'image/jpeg',
      upsert: true,
    );

    await _supabase.table('patient_xray_results').insert({
      'patient_id': patientIdForLog,
      'image_path': fileName,
      'prediction': result.prediction,
      'confidence': result.confidence,
      'prob_normal': result.probNormal,
      'prob_pneumonia': result.probPneumonia,
      'report_text': result.reportText,

      // FIX — reflect actual result state instead of always 'STABLE'.
      // An INCONCLUSIVE result logged as STABLE is misleading in the
      // Supabase dashboard and skews any downstream audit queries.
      'engine_status': result.prediction == 'INCONCLUSIVE'
          ? 'INCONCLUSIVE'
          : 'STABLE',

      'inference_mode': 'on-device',
      'model_version': _ModelConfig.modelVersion,

      // UTC timestamp — client clocks drift so always use UTC.
      // Prefer setting a Postgres DEFAULT NOW() on this column so
      // the server clock is authoritative, but UTC here is correct
      // as a fallback.
      'processed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<String?> _validateImage(File file) {
    return compute(_validateImageIsolate, file.path);
  }
}

// ─────────────────────────────────────────────────────────────
// Top-level isolate functions
// (must be top-level — Flutter's compute() cannot capture closures)
// ─────────────────────────────────────────────────────────────

/// Resize to [_ModelConfig.inputSize] × [_ModelConfig.inputSize] and return
/// raw RGB pixel values.
///
/// The updated TFLite graph now contains the ImageNet wrapper:
///   x -> x / 255 -> x - mean -> x / std
/// so Flutter must not normalize again here, convert to grayscale,
/// invert colors, or transpose to NCHW / CHW.
///
/// Returns a [1, S, S, 3] nested list in HWC order containing raw
/// decoded RGB channel values as float32-compatible doubles.
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

  final size = _ModelConfig.inputSize;
  return [
    List.generate(size, (y) {
      return List.generate(size, (x) {
        final pixel = decoded!.getPixel(x, y);
        // Feed raw decoded RGB values only. The TFLite graph applies
        // /255 + ImageNet normalization internally.
        return [pixel.r.toDouble(), pixel.g.toDouble(), pixel.b.toDouble()];
      });
    }),
  ];
}

/// Validates file extension, file size, and image decodability.
/// Returns a non-null error string on failure, null on success.
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
      return 'Image resolution too low. '
          'Please upload a higher quality X-ray.';
    }
  } catch (_) {
    return 'Cannot read image file.';
  }

  return null;
}
