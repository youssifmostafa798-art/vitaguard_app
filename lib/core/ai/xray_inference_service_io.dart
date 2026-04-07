import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:vitaguard_app/patient/data/patient_models.dart';

class XrayInferenceService {
  XrayInferenceService._();

  static final XrayInferenceService instance = XrayInferenceService._();

  Interpreter? _interpreter;
  List<int>? _inputShape;
  List<int>? _outputShape;
  TensorType? _inputType;
  bool _loading = false;

  bool get isReady => _interpreter != null;

  Future<void> ensureLoaded() async {
    if (_interpreter != null || _loading) return;
    _loading = true;
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model_optimized.tflite',
      );
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _inputType = _interpreter!.getInputTensor(0).type;
      _outputShape = _interpreter!.getOutputTensor(0).shape;
    } finally {
      _loading = false;
    }
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

    await ensureLoaded();
    if (_interpreter == null || _inputShape == null || _outputShape == null) {
      return XRayResult(
        isValid: false,
        prediction: null,
        confidence: null,
        reportText: 'AI model not available. Please try again later.',
        imagePath: imageFile.path,
      );
    }

    final input = await _preprocess(imageFile, _inputShape!);
    final output = _createOutputBuffer(_outputShape!);
    _interpreter!.run(input, output);

    final flat = _flattenOutput(output);
    if (flat.isEmpty) {
      return XRayResult(
        isValid: false,
        prediction: null,
        confidence: null,
        reportText: 'AI inference failed. Please try another image.',
        imagePath: imageFile.path,
      );
    }

    String prediction;
    double confidence;
    if (flat.length >= 2) {
      final p0 = flat[0];
      final p1 = flat[1];
      if (p1 >= p0) {
        prediction = 'PNEUMONIA';
        confidence = p1;
      } else {
        prediction = 'NORMAL';
        confidence = p0;
      }
    } else {
      final prob = flat[0];
      if (prob >= 0.5) {
        prediction = 'PNEUMONIA';
        confidence = prob;
      } else {
        prediction = 'NORMAL';
        confidence = 1.0 - prob;
      }
    }

    final reportText = _generateReport(prediction, confidence);
    return XRayResult(
      isValid: true,
      prediction: prediction,
      confidence: confidence,
      reportText: reportText,
      imagePath: imageFile.path,
    );
  }

  Future<String?> _validateImage(File file) {
    return compute(_validateImageIsolate, file.path);
  }

  Future<Object> _preprocess(File file, List<int> inputShape) async {
    final height = inputShape[1];
    final width = inputShape[2];
    final channels = inputShape.length > 3 ? inputShape[3] : 1;
    final args = <String, dynamic>{
      'path': file.path,
      'width': width,
      'height': height,
      'channels': channels,
    };

    if (_inputType == TensorType.uint8) {
      final buffer = await compute(_preprocessUint8Isolate, args);
      return buffer.reshape([1, height, width, channels]);
    }

    final buffer = await compute(_preprocessFloat32Isolate, args);
    return buffer.reshape([1, height, width, channels]);
  }

  dynamic _createOutputBuffer(List<int> shape) {
    if (shape.length == 1) {
      return List<double>.filled(shape[0], 0.0);
    }
    return List.generate(
      shape[0],
      (_) => _createOutputBuffer(shape.sublist(1)),
    );
  }

  List<double> _flattenOutput(dynamic output) {
    if (output is double) {
      return [output];
    }
    if (output is int) {
      return [output.toDouble()];
    }
    if (output is List) {
      return output.expand(_flattenOutput).toList();
    }
    if (output is Float32List) {
      return output.toList();
    }
    return [];
  }

  String _generateReport(String prediction, double confidence) {
    final confidencePct = (confidence * 100).clamp(0, 100).toStringAsFixed(1);
    if (prediction == 'PNEUMONIA') {
      return [
        'The scan shows findings suggestive of pneumonia.',
        'Confidence: $confidencePct%.',
        'Clinical correlation and medical follow-up are recommended.',
        'This is a preliminary automated report and does not replace a physician diagnosis.',
      ].join('\n');
    }
    return [
      'The scan does not show significant findings suggestive of pneumonia.',
      'Confidence: $confidencePct%.',
      'Routine follow-up is recommended as appropriate.',
      'This is a preliminary automated report and does not replace a physician diagnosis.',
    ].join('\n');
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

Uint8List _preprocessUint8Isolate(Map<String, dynamic> args) {
  final path = args['path'] as String;
  final width = args['width'] as int;
  final height = args['height'] as int;
  final channels = args['channels'] as int;

  final bytes = File(path).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Failed to decode image.');
  }
  final resized = img.copyResize(decoded, width: width, height: height);

  final buffer = Uint8List(width * height * channels);
  int i = 0;
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final pixel = resized.getPixel(x, y);
      if (channels == 1) {
        buffer[i++] = pixel.luminance.toInt();
      } else {
        buffer[i++] = pixel.r.toInt();
        buffer[i++] = pixel.g.toInt();
        buffer[i++] = pixel.b.toInt();
      }
    }
  }
  return buffer;
}

Float32List _preprocessFloat32Isolate(Map<String, dynamic> args) {
  final path = args['path'] as String;
  final width = args['width'] as int;
  final height = args['height'] as int;
  final channels = args['channels'] as int;

  final bytes = File(path).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('Failed to decode image.');
  }
  final resized = img.copyResize(decoded, width: width, height: height);

  final buffer = Float32List(width * height * channels);
  int i = 0;
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final pixel = resized.getPixel(x, y);
      if (channels == 1) {
        buffer[i++] = pixel.luminance / 255.0;
      } else {
        buffer[i++] = pixel.r / 255.0;
        buffer[i++] = pixel.g / 255.0;
        buffer[i++] = pixel.b / 255.0;
      }
    }
  }
  return buffer;
}
