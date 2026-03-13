import 'package:flutter/material.dart';
import 'package:vitaguard_app/core/ai/xray_inference_service.dart';

class HealthProvider with ChangeNotifier {
  bool _isAiOnline = false;
  String _aiMessage = 'Checking AI status...';

  bool get isAiOnline => _isAiOnline;
  String get aiMessage => _aiMessage;

  HealthProvider() {
    checkHealth();
  }

  Future<void> checkHealth() async {
    try {
      await XrayInferenceService.instance.ensureLoaded();
      _isAiOnline = XrayInferenceService.instance.isReady;
      _aiMessage = _isAiOnline ? 'AI model loaded' : 'AI model not available';
    } catch (e) {
      _isAiOnline = false;
      _aiMessage = 'AI model error';
    }
    notifyListeners();
  }
}
