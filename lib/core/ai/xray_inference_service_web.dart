import 'package:vitaguard_app/patient/models/patient_models.dart';

class XrayInferenceService {
  XrayInferenceService._();

  static final XrayInferenceService instance = XrayInferenceService._();

  bool get isReady => false;

  Future<void> ensureLoaded() async {}

  Future<XRayResult> analyze(Object imageFile) async {
    return XRayResult(
      isValid: false,
      prediction: null,
      confidence: null,
      reportText: 'X-ray AI is not supported on Web. Use Android or iOS.',
      imagePath: '',
    );
  }
}
