import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

/// Clinical Thresholds as defined by Medical Standards
class ClinicalThresholds {
  static const double criticalLowSpO2 = 89.0;
  static const double lowBPM = 60.0;
  
  // Timing
  static const Duration alertDelay = Duration(seconds: 30);
  static const Duration evaluationInterval = Duration(seconds: 5);
}

enum VitalAlertType {
  none,
  criticalSpO2,
  lowBPM,
}

class VitalAlertState {
  final VitalAlertType type;
  final String message;
  final DateTime? startTime;
  final bool isTriggered;

  VitalAlertState({
    this.type = VitalAlertType.none,
    this.message = '',
    this.startTime,
    this.isTriggered = false,
  });

  VitalAlertState copyWith({
    VitalAlertType? type,
    String? message,
    DateTime? startTime,
    bool? isTriggered,
  }) {
    return VitalAlertState(
      type: type ?? this.type,
      message: message ?? this.message,
      startTime: startTime ?? this.startTime,
      isTriggered: isTriggered ?? this.isTriggered,
    );
  }
}

/// Senior Staff Engineer Implementation: VitalAlertService
/// Responsible for stateful, time-based validation of clinical vitals.
class VitalAlertService extends StateNotifier<VitalAlertState> {
  VitalAlertService() : super(VitalAlertState());

  Timer? _evalTimer;
  DateTime? _spO2ViolationStart;
  DateTime? _bpmViolationStart;

  /// Entry point for real-time telemetry updates
  void processMetrics({required double spo2, required double bpm}) {
    final now = DateTime.now();

    // 1. SpO2 Evaluation
    if (spo2 > 0 && spo2 < ClinicalThresholds.criticalLowSpO2) {
      _spO2ViolationStart ??= now;
    } else {
      _spO2ViolationStart = null;
    }

    // 2. BPM Evaluation
    if (bpm > 0 && bpm < ClinicalThresholds.lowBPM) {
      _bpmViolationStart ??= now;
    } else {
      _bpmViolationStart = null;
    }

    _evaluateConditions(now);
  }

  void _evaluateConditions(DateTime now) {
    // Priority 1: Critical SpO2 (Life Threatening)
    if (_spO2ViolationStart != null) {
      final duration = now.difference(_spO2ViolationStart!);
      if (duration >= ClinicalThresholds.alertDelay) {
        _triggerAlert(
          VitalAlertType.criticalSpO2,
          'CRITICAL: SpO2 has been below 89% for ${duration.inSeconds}s',
          _spO2ViolationStart!,
        );
        return;
      }
    }

    // Priority 2: Low Heart Rate
    if (_bpmViolationStart != null) {
      final duration = now.difference(_bpmViolationStart!);
      if (duration >= ClinicalThresholds.alertDelay) {
        _triggerAlert(
          VitalAlertType.lowBPM,
          'ALERT: Heart Rate has been below 60 BPM for ${duration.inSeconds}s',
          _bpmViolationStart!,
        );
        return;
      }
    }

    // Reset if conditions are no longer met
    if (_spO2ViolationStart == null && _bpmViolationStart == null) {
      if (state.type != VitalAlertType.none) {
        state = VitalAlertState();
      }
    }
  }

  void _triggerAlert(VitalAlertType type, String message, DateTime start) {
    // Avoid redundant state updates if already triggered for same cause
    if (state.type == type && state.isTriggered) return;

    state = VitalAlertState(
      type: type,
      message: message,
      startTime: start,
      isTriggered: true,
    );
  }

  void resetManual() {
    _spO2ViolationStart = null;
    _bpmViolationStart = null;
    state = VitalAlertState();
  }
}

final vitalAlertProvider = StateNotifierProvider<VitalAlertService, VitalAlertState>((ref) {
  return VitalAlertService();
});
