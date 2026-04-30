import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vitaguard_app/core/ai/xray_inference_service.dart';

part 'health_provider.g.dart';

class HealthState {
  final bool isAiOnline;
  final String aiMessage;

  HealthState({
    this.isAiOnline = false,
    this.aiMessage = 'Checking AI status...',
  });
}

@riverpod
class HealthController extends _$HealthController {
  @override
  HealthState build() {
    _init();
    return HealthState();
  }

  Future<void> _init() async {
    await checkHealth();
  }

  Future<void> checkHealth() async {
    try {
      await XrayInferenceService.instance.ensureLoaded();
      final ready = XrayInferenceService.instance.isReady;
      state = HealthState(
        isAiOnline: ready,
        aiMessage: ready ? 'AI model loaded' : 'AI model not available',
      );
    } catch (e) {
      state = HealthState(isAiOnline: false, aiMessage: 'AI model error');
    }
  }
}
