import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';

final _log = Logger();

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
// Input tensor diagnostics
// ─────────────────────────────────────────────────────────────

/// Summarizes the raw input tensor for debugging.
/// The updated TFLite asset now owns ImageNet normalization inside
/// the graph itself, so Flutter must feed raw RGB pixel values in
/// the range [0, 255] after resize.
String _summarizeInputTensor(List<List<List<List<double>>>> t) {
  // t shape: [1, H, W, 3]
  try {
    final h = t[0].length;
    final w = t[0][0].length;
    final expectedLen = _ModelConfig.inputSize * _ModelConfig.inputSize * 3;
    final actualLen = h * w * 3;
    var n = 0;
    var rSum = 0.0, gSum = 0.0, bSum = 0.0;
    var rMin = double.infinity, gMin = double.infinity, bMin = double.infinity;
    var rMax = -double.infinity,
        gMax = -double.infinity,
        bMax = -double.infinity;
    var rgDiffSum = 0.0, rbDiffSum = 0.0, gbDiffSum = 0.0;

    for (final row in t[0]) {
      for (final px in row) {
        final r = px[0], g = px[1], b = px[2];
        n++;
        rSum += r;
        gSum += g;
        bSum += b;
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
    final sampleValues = <String>[];
    for (var i = 0; i < math.min(3, h); i++) {
      for (var j = 0; j < math.min(3, w); j++) {
        final px = t[0][i][j];
        sampleValues.add(
          '[$i,$j]=(${px[0].toStringAsFixed(1)},'
          '${px[1].toStringAsFixed(1)},${px[2].toStringAsFixed(1)})',
        );
      }
    }

    final warning = StringBuffer();
    final maxVal = math.max(rMax, math.max(gMax, bMax));
    if (maxVal <= 1.0) {
      warning.write(
        ' [WARNING values look normalized to 0..1; remove Dart-side /255 '
        'or other normalization because the graph already does it]',
      );
    } else if (maxVal > 255.0) {
      warning.write(
        ' [WARNING values exceed 255; check pixel extraction / buffer layout]',
      );
    } else {
      warning.write(' [OK raw pixel range looks correct]');
    }

    return '[TFLITE] Input stats (raw RGB 0..255) ${h}x$w: '
        'bufferLen=$actualLen expectedLen=$expectedLen '
        'R[min=${rMin.toStringAsFixed(3)}, max=${rMax.toStringAsFixed(3)}, mean=${rMean.toStringAsFixed(3)}] '
        'G[min=${gMin.toStringAsFixed(3)}, max=${gMax.toStringAsFixed(3)}, mean=${gMean.toStringAsFixed(3)}] '
        'B[min=${bMin.toStringAsFixed(3)}, max=${bMax.toStringAsFixed(3)}, mean=${bMean.toStringAsFixed(3)}] '
        'avg|R-G|=${rg.toStringAsFixed(4)} avg|R-B|=${rb.toStringAsFixed(4)} avg|G-B|=${gb.toStringAsFixed(4)} '
        'samples=${sampleValues.join(", ")}$warning';
  } catch (_) {
    return '[TFLITE] Input stats unavailable';
  }
}

String _summarizeTwoClassOutput(double v0, double v1) {
  final sum = v0 + v1;
  final looksSoftmaxed = v0 >= 0.0 && v1 >= 0.0 && (sum - 1.0).abs() < 0.01;
  if (looksSoftmaxed) {
    return '[TFLITE] Output sanity: values look like probabilities already '
        '(sum~1, all positive). If the graph already includes softmax, do not '
        'apply softmax again in Dart.';
  }
  return '[TFLITE] Output sanity: values look like raw logits; apply softmax '
      'exactly once in Dart.';
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
  static const double pneumoniaThreshold = 0.5471;
  static const double inconclusiveLow = 0.3971;

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
  bool _isInitializing = false;

  bool get isReady => _interpreter != null;

  final _supabase = Supabase.instance.client;

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
      _log.i(
        '[TFLITE] Loading model asset: ${_ModelConfig.assetPath} | '
        'version=${_ModelConfig.modelVersion}',
      );
      Interpreter? interp;

      // Attempt 1 — GPU delegate (faster on supported devices)
      try {
        final opts = InterpreterOptions()..addDelegate(GpuDelegateV2());
        interp = await Interpreter.fromAsset(
          _ModelConfig.assetPath,
          options: opts,
        );
        _log.i('[TFLITE] Loaded with GPU delegate.');
      } catch (gpuErr) {
        _log.w('[TFLITE] GPU delegate unavailable: $gpuErr');

        // Attempt 2 — CPU fallback
        try {
          interp = await Interpreter.fromAsset(_ModelConfig.assetPath);
          _log.i('[TFLITE] Loaded on CPU.');
        } catch (cpuErr) {
          _log.e('[TFLITE] CPU load also failed: $cpuErr');
          rethrow;
        }
      }

      _interpreter = interp;

      // ── Tensor shape verification ────────────────────────
      final initialInShape = _interpreter!.getInputTensor(0).shape;

      if (initialInShape[1] != _ModelConfig.inputSize ||
          initialInShape[2] != _ModelConfig.inputSize) {
        // The exported model's baked-in shape differs from inputSize.
        // Attempt a dynamic resize — note that GPU delegates often do
        // NOT support this and will throw. If resize fails the error
        // is rethrown so the caller knows the model is incompatible.
        _log.w(
          '[TFLITE] Input shape mismatch: $initialInShape — '
              'attempting resize to '
              '[1, ${_ModelConfig.inputSize}, ${_ModelConfig.inputSize}, 3]. '
              'If this crashes the GPU delegate, re-export the model at '
              '${_ModelConfig.inputSize}×${_ModelConfig.inputSize}.',
        );
        try {
          _interpreter!.resizeInputTensor(0, [
            1,
            _ModelConfig.inputSize,
            _ModelConfig.inputSize,
            3,
          ]);
          _interpreter!.allocateTensors();
        } catch (resizeErr) {
          _log.e(
            '[TFLITE] Tensor resize failed: $resizeErr. '
                'The model must be re-exported at the correct input size.',
          );
          rethrow;
        }
      }

      final inShape = _interpreter!.getInputTensor(0).shape;
      final outShape = _interpreter!.getOutputTensor(0).shape;
      _log.i('[TFLITE] Input shape: $inShape | Output shape: $outShape');

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
  Future<XRayResult> analyze(File imageFile) async {
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
      if (_interpreter == null) {
        throw StateError('TFLite interpreter failed to initialize.');
      }

      // Step 3 — preprocess in background isolate
      // Produces [1, 320, 320, 3] float32 nested list (HWC layout)
      // containing raw RGB values in [0, 255]. The TFLite graph now
      // applies the ImageNet wrapper internally.
      final sw = Stopwatch()..start();
      final inputTensor = await compute(_preprocessImage, imageFile.path);
      _log.d('[TFLITE] Preprocessing: ${sw.elapsedMilliseconds}ms');
      _log.d(
        '[TFLITE] Model asset: ${_ModelConfig.assetPath} | '
        'version=${_ModelConfig.modelVersion}',
      );

      // Sanity-check the raw tensor statistics before the model's
      // built-in preprocessing wrapper executes. For raw pixels we
      // expect min/max near 0..255 rather than already-normalized values.
      _log.i(_summarizeInputTensor(inputTensor));

      // Step 4 — run inference
      final outShape = _interpreter!.getOutputTensor(0).shape;
      _log.d('[TFLITE] Runtime output shape: $outShape');

      double probNormal;
      double probPneumonia;

      if (outShape.length == 2 && outShape[1] == 2) {
        // Standard two-class head: [1, 2] raw logits
        // (CrossEntropyLoss export — softmax not baked in).
        // Exported class order is fixed: [NORMAL, PNEUMONIA].
        final output = [List.filled(2, 0.0)];
        _interpreter!.run(inputTensor, output);
        sw.stop();
        final z0 = output[0][0]; // NORMAL logit
        final z1 = output[0][1]; // PNEUMONIA logit
        _log.i(
          '[TFLITE] Raw logits [1,2] (NORMAL, PNEUMONIA): '
              '${sw.elapsedMilliseconds}ms | [$z0, $z1]',
        );
        _log.i(_summarizeTwoClassOutput(z0, z1));
        final probs = _toProbs(z0, z1);
        probNormal = probs[0];
        probPneumonia = probs[1];
        _log.i(
          '[TFLITE] Softmax probs (single pass): '
              'normal=$probNormal | pneumonia=$probPneumonia',
        );
      } else if (outShape.length == 2 && outShape[1] == 1) {
        // Sigmoid single-output head: [1, 1] → P(PNEUMONIA)
        final output = [List.filled(1, 0.0)];
        _interpreter!.run(inputTensor, output);
        sw.stop();
        final sigmoid = output[0][0];
        _log.i(
          '[TFLITE] Sigmoid [1,1]: '
              '${sw.elapsedMilliseconds}ms | raw=$sigmoid',
        );
        probPneumonia = sigmoid;
        probNormal = 1.0 - sigmoid;
      } else {
        // Unexpected shape — try flat list as last resort
        _log.w(
          '[TFLITE] Unknown output shape $outShape, '
              'trying flat output...',
        );
        final flat = List.filled(outShape.reduce((a, b) => a * b), 0.0);
        _interpreter!.run(inputTensor, flat);
        sw.stop();
        _log.i(
          '[TFLITE] Flat inference: '
              '${sw.elapsedMilliseconds}ms | raw=$flat',
        );
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
      // pneumoniaThreshold (0.5471): trained threshold from calibration
      //   on the held-out test set. A score at or above this value
      //   is classified as PNEUMONIA.
      //
      // inconclusiveLow (0.3971): scores between 0.3971 and 0.5471
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

      _log.i(
        '[TFLITE] Result: $prediction | '
            'conf=${(confidence * 100).toStringAsFixed(1)}% | '
            'normal=${(probNormal * 100).toStringAsFixed(1)}% | '
            'pneumonia=${(probPneumonia * 100).toStringAsFixed(1)}%',
      );

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
  Future<void> _logToSupabase(File imageFile, XRayResult result) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final bytes = await imageFile.readAsBytes();
    final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';

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

    await _supabase.from('patient_xray_results').insert({
      'patient_id': user.id,
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

    _log.i('[SUPABASE] Prediction logged.');
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
        return [
          pixel.r.toDouble(),
          pixel.g.toDouble(),
          pixel.b.toDouble(),
        ];
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
