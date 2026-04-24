import 'package:flutter/material.dart';

enum AlertSeverity { normal, warning, critical, sensorError }

class VitalThresholds {
  static const int heartRateLow = 50;
  static const int heartRateHigh = 120;
  static const int spo2Low = 92;
  static const int spo2Critical = 88;
  static const double tempHigh = 38.5;

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
