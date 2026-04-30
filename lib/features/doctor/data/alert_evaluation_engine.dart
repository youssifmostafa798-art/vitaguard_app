import 'package:vitaguard_app/data/models/doctor/vital_alert_model.dart';

class AlertEvaluationEngine {
  // Per-metric cooldown trackers
  final Map<String, DateTime> _lastAlertTimes = {};
  final Duration _cooldown = const Duration(seconds: 45); // Cooldown to prevent spam

  // Rolling windows for smoothing (last 5 readings)
  final Map<String, List<double>> _windows = {
    'hr': [],
    'spo2': [],
    'temp': []
  };

  List<VitalAlert> evaluate({
    required String patientId,
    required int? hr,
    required int? spo2,
    required double? temp,
  }) {
    List<VitalAlert> alerts = [];
    final now = DateTime.now();

    // 1. Check for Disconnect / No Data (Highest Priority)
    if (hr == null || spo2 == null || hr <= 0) {
      if (_canTrigger(patientId, "System")) {
        alerts.add(VitalAlert(
          metrics: ["System"],
          message: "Sensor Disconnected or No Data",
          severity: AlertSeverity.sensorError,
          timestamp: now,
          rawValues: {},
        ));
        _markTriggered(patientId, "System");
      }
      return alerts;
    }

    // 2. Smoothing / Signal Quality
    _addToWindow('hr', hr.toDouble());
    _addToWindow('spo2', spo2.toDouble());
    if (temp != null) _addToWindow('temp', temp);

    final avgHR = _getAvg('hr');
    final avgSpO2 = _getAvg('spo2');
    final avgTemp = _getAvg('temp');

    // 3. Multi-variate Logic (The "Respiratory/Cardiac Distress" Rule)
    if (avgSpO2 < VitalThresholds.spo2Warning && avgHR > VitalThresholds.heartRateHigh) {
      if (_canTrigger(patientId, "Combined")) {
        alerts.add(VitalAlert(
          metrics: ["SpO2", "HR"],
          message: "CRITICAL: Low Oxygen + High Heart Rate",
          severity: AlertSeverity.critical,
          timestamp: now,
          rawValues: {"hr": hr, "spo2": spo2},
        ));
        _markTriggered(patientId, "Combined");
        return alerts; // Multi-variate takes precedence
      }
    }

    // 4. Independent Thresholds

    // SpO2 Critical
    if (avgSpO2 < VitalThresholds.spo2Critical && _canTrigger(patientId, "SpO2_Critical")) {
      alerts.add(VitalAlert(
        metrics: ["SpO2"],
        message: "Critical Oxygen Level: ${avgSpO2.toInt()}%",
        severity: AlertSeverity.critical,
        timestamp: now,
        rawValues: {"spo2": spo2},
      ));
      _markTriggered(patientId, "SpO2_Critical");
    }
    // SpO2 Warning
    else if (avgSpO2 < VitalThresholds.spo2Warning && _canTrigger(patientId, "SpO2_Warning")) {
      alerts.add(VitalAlert(
        metrics: ["SpO2"],
        message: "Low Oxygen Level: ${avgSpO2.toInt()}%",
        severity: AlertSeverity.warning,
        timestamp: now,
        rawValues: {"spo2": spo2},
      ));
      _markTriggered(patientId, "SpO2_Warning");
    }

    // Heart Rate High
    if (avgHR > VitalThresholds.heartRateHigh && _canTrigger(patientId, "HR_High")) {
      alerts.add(VitalAlert(
        metrics: ["Heart Rate"],
        message: "Tachycardia Detected: ${avgHR.toInt()} bpm",
        severity: AlertSeverity.warning,
        timestamp: now,
        rawValues: {"hr": hr},
      ));
      _markTriggered(patientId, "HR_High");
    }
    // Heart Rate Low
    else if (avgHR < VitalThresholds.heartRateLow && _canTrigger(patientId, "HR_Low")) {
      alerts.add(VitalAlert(
        metrics: ["Heart Rate"],
        message: "Bradycardia Detected: ${avgHR.toInt()} bpm",
        severity: AlertSeverity.warning,
        timestamp: now,
        rawValues: {"hr": hr},
      ));
      _markTriggered(patientId, "HR_Low");
    }

    // Temperature High
    if (avgTemp > VitalThresholds.tempWarning && _canTrigger(patientId, "Temp_High")) {
      alerts.add(VitalAlert(
        metrics: ["Temperature"],
        message: "Fever Detected: ${avgTemp.toStringAsFixed(1)}°C",
        severity: AlertSeverity.warning,
        timestamp: now,
        rawValues: {"temp": temp},
      ));
      _markTriggered(patientId, "Temp_High");
    }

    return alerts;
  }

  bool _canTrigger(String patientId, String type) {
    final key = "${patientId}_$type";
    final lastTime = _lastAlertTimes[key];
    if (lastTime == null) return true;
    return DateTime.now().difference(lastTime) > _cooldown;
  }

  void _markTriggered(String patientId, String type) {
    final key = "${patientId}_$type";
    _lastAlertTimes[key] = DateTime.now();
  }

  void _addToWindow(String key, double val) {
    _windows[key]!.add(val);
    if (_windows[key]!.length > 5) _windows[key]!.removeAt(0);
  }

  double _getAvg(String key) =>
    _windows[key]!.isEmpty ? 0 : _windows[key]!.reduce((a, b) => a + b) / _windows[key]!.length;
}
