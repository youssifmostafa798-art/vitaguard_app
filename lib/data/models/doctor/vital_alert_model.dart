import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Severity
// ---------------------------------------------------------------------------

enum AlertSeverity { normal, warning, critical, sensorError }

// ---------------------------------------------------------------------------
// Thresholds — firmware-aligned
// ---------------------------------------------------------------------------

class VitalThresholds {
  // Heart rate
  static const int heartRateLow  = 60;
  static const int heartRateHigh = 120;

  // SpO2 — two-level
  static const int spo2Warning  = 92; // < 92 → orange warning
  static const int spo2Critical = 88; // < 88 → red critical

  // Temperature — two-level
  static const double tempWarning  = 38.5;
  static const double tempCritical = 39.5;

  // Onset delay (matches firmware ALERT_DELAY_MS = 45 000 ms)
  static const Duration alertOnsetDelay = Duration(seconds: 45);

  // Cooldown between successive alerts for the same metric
  static const Duration alertCooldownDuration = Duration(seconds: 12);

  // Stale-sensor watchdog — cancel timers if no new data for this long
  static const Duration staleTimeout = Duration(seconds: 60);

  // ---------------------------------------------------------------------------

  static Color getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.sensorError:
        return Colors.blueGrey;
      default:
        return Colors.green;
    }
  }
}

// ---------------------------------------------------------------------------
// VitalAlert — a single triggered alert event
// ---------------------------------------------------------------------------

class VitalAlert {
  final String id;
  final List<String> metrics;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> rawValues;
  bool isAcknowledged;

  VitalAlert({
    String? id,
    required this.metrics,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.rawValues,
    this.isAcknowledged = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'metrics': metrics,
        'message': message,
        'severity': severity.name,
        'timestamp': timestamp.toIso8601String(),
        'raw_values': rawValues,
        'is_acknowledged': isAcknowledged,
      };
}

// ---------------------------------------------------------------------------
// PreAlertInfo — emitted while the 45-second delay window is running
// ---------------------------------------------------------------------------

class PreAlertInfo {
  final String metric;
  final Duration elapsed;
  final Duration target;

  const PreAlertInfo({
    required this.metric,
    required this.elapsed,
    required this.target,
  });

  /// Normalised progress [0.0 → 1.0].
  /// Computed here so widgets never do time math.
  double get progress =>
      (elapsed.inMilliseconds / target.inMilliseconds).clamp(0.0, 1.0);

  String get label => 'Monitoring abnormal $metric reading…';
}

// ---------------------------------------------------------------------------
// VitalAlertState — the single value emitted by AlertTimerService
// ---------------------------------------------------------------------------

class VitalAlertState {
  /// Highest-priority active alert (null → all clear).
  final VitalAlert? primaryAlert;

  /// All simultaneously active alerts, sorted critical → warning.
  final List<VitalAlert> allAlerts;

  /// Pre-alert info while the delay window is running (null if none).
  final PreAlertInfo? preAlert;

  const VitalAlertState({
    this.primaryAlert,
    this.allAlerts = const [],
    this.preAlert,
  });

  bool get hasAlert    => primaryAlert != null;
  bool get hasPreAlert => !hasAlert && preAlert != null;

  /// Convenience: colour to use for metric-card borders, ring, etc.
  Color get statusColor {
    if (primaryAlert != null) {
      return VitalThresholds.getSeverityColor(primaryAlert!.severity);
    }
    if (preAlert != null) return Colors.orange.withValues(alpha: 0.7);
    return Colors.green;
  }

  static const normal = VitalAlertState();
}
