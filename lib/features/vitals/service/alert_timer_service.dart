import 'dart:async';
import 'package:vitaguard_app/data/models/doctor/vital_alert_model.dart';

/// Pure-Dart stateful service — no Flutter imports.
///
/// One instance per [HardwareScreen] — never a singleton.
/// Emits [VitalAlertState] via a broadcast stream that any number of
/// [StreamBuilder]s can listen to simultaneously.
///
/// ## Timer architecture
/// - One **45 s one-shot** timer per metric (fires the alert).
/// - One shared **1 s periodic** tick timer (drives the progress bar).
/// - One **60 s stale watchdog** (cancels everything on sensor loss).
/// - Background/foreground handled via [onBackground] / [onForeground].
class AlertTimerService {
  // ── Configuration ─────────────────────────────────────────────────────────

  static const _alertOnsetDelay      = VitalThresholds.alertOnsetDelay;
  static const _alertCooldownDuration = VitalThresholds.alertCooldownDuration;
  static const _staleTimeout          = VitalThresholds.staleTimeout;

  // ── State ──────────────────────────────────────────────────────────────────

  /// When each metric's continuous abnormality *began*.
  final Map<String, DateTime> _onsetTimes = {};

  /// 45-s one-shot timers, keyed by metric name.
  final Map<String, Timer> _onsetTimers = {};

  /// Anti-spam cooldown end times, keyed by metric name.
  final Map<String, DateTime> _cooldownEnds = {};

  /// Currently fired (active) alerts — sorted by severity on mutation.
  final List<VitalAlert> _activeAlerts = [];

  /// Most recent raw vitals — used by [_buildAlert] at fire-time.
  final Map<String, num> _lastKnownValues = {};

  Timer? _tickTimer;
  Timer? _staleWatchdog;

  /// Non-null while the app is backgrounded.
  DateTime? _backgroundedAt;

  // ── Output stream ──────────────────────────────────────────────────────────

  final _ctrl = StreamController<VitalAlertState>.broadcast();

  /// Listen to this in [StreamBuilder]s.
  Stream<VitalAlertState> get alertStream => _ctrl.stream;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Call this on every new vitals record from Supabase.
  ///
  /// [deviceStatus] values `FALL_DETECTED`, `EMERGENCY_BUTTON`,
  /// and `EMERGENCY_NO_PULSE` bypass the 45-s delay and fire immediately.
  void evaluate({
    int?    bpm,
    int?    spo2,
    double? temp,
    String? deviceStatus,
  }) {
    if (_ctrl.isClosed) return;

    // Persist latest raw values for use at fire-time.
    if (bpm  != null) _lastKnownValues['bpm']  = bpm;
    if (spo2 != null) _lastKnownValues['spo2'] = spo2;
    if (temp != null) _lastKnownValues['temp'] = temp;

    // Reset stale watchdog on every incoming reading.
    _resetStaleWatchdog();

    // ── 1. Immediate path — emergency device_status ────────────────────────
    const emergencyStatuses = {
      'FALL_DETECTED',
      'EMERGENCY_BUTTON',
      'EMERGENCY_NO_PULSE',
    };
    if (deviceStatus != null && emergencyStatuses.contains(deviceStatus)) {
      _emitImmediateAlert(deviceStatus);
      return; // Do not run threshold checks after an emergency
    }

    // ── 2. Threshold evaluation ────────────────────────────────────────────
    _evaluateSpO2(spo2);
    _evaluateBpm(bpm);
    _evaluateTemp(temp);

    _emitCurrentState();
  }

  /// Called by [WidgetsBindingObserver.didChangeAppLifecycleState] on pause.
  void onBackground() {
    _backgroundedAt = DateTime.now();

    // Cancel all pending timers — KEEP _onsetTimes intact.
    for (final t in _onsetTimers.values) {
      t.cancel();
    }
    _onsetTimers.clear();
    _tickTimer?.cancel();
    _tickTimer = null;

    // Pause stale watchdog — absence is intentional while backgrounded.
    _staleWatchdog?.cancel();
    _staleWatchdog = null;
  }

  /// Called by [WidgetsBindingObserver.didChangeAppLifecycleState] on resume.
  void onForeground() {
    if (_backgroundedAt == null) return;
    _backgroundedAt = null;

    final now = DateTime.now();

    // Restart a timer for every metric that had an in-progress onset.
    for (final entry in List.of(_onsetTimes.entries)) {
      final metric  = entry.key;
      final elapsed = now.difference(entry.value);
      final remaining = _alertOnsetDelay - elapsed;

      if (remaining <= Duration.zero) {
        // Onset window fully elapsed while backgrounded — fire immediately.
        _onAlertFired(metric, _buildAlert(metric));
      } else {
        _onsetTimers[metric] = Timer(
          remaining,
          () => _onAlertFired(metric, _buildAlert(metric)),
        );
      }
    }

    // Restart 1-s tick if any metric is still in pre-alert.
    if (_onsetTimes.isNotEmpty && _activeAlerts.isEmpty) {
      _startTickTimer();
    }

    _resetStaleWatchdog();
    _emitCurrentState();
  }

  /// Dismiss the current active alert(s) — snooze semantics.
  ///
  /// Clears the active alert list, marks a 12-second cooldown for every
  /// currently tracked metric, and cancels pending onset timers.
  /// After the cooldown expires, the next [evaluate] call will restart
  /// the 45-second onset timer if the value is still abnormal.
  ///
  /// **Re-fire timeline:** cooldown (12s) + onset (45s) = 57s minimum.
  void snooze() {
    // Mark cooldown for every metric that has an onset or active alert.
    final allMetrics = {
      ..._onsetTimes.keys,
      ..._activeAlerts.expand((a) => a.metrics),
    };

    for (final metric in allMetrics) {
      _markCooldown(metric);
      _onsetTimers[metric]?.cancel();
      _onsetTimers.remove(metric);
      _onsetTimes.remove(metric);
    }

    _activeAlerts.clear();
    _tickTimer?.cancel();
    _tickTimer = null;

    _emitCurrentState();
  }

  void dispose() {
    for (final t in _onsetTimers.values) {
      t.cancel();
    }
    _tickTimer?.cancel();
    _staleWatchdog?.cancel();
    _ctrl.close();
  }

  // ── Threshold evaluators ───────────────────────────────────────────────────

  void _evaluateSpO2(int? spo2) {
    if (spo2 == null) return;

    const metric = 'SpO2';

    if (spo2 < VitalThresholds.spo2Critical) {
      // CRITICAL — inherit or escalate from any existing warning onset.
      _startOrEscalateTimer(metric, AlertSeverity.critical);
    } else if (spo2 < VitalThresholds.spo2Warning) {
      // WARNING — start fresh or de-escalate (reset to zero if was critical).
      _startOrDeescalateTimer(metric, AlertSeverity.warning);
    } else {
      // Normal — cancel any pending timer.
      _cancelTimer(metric);
    }
  }

  void _evaluateBpm(int? bpm) {
    if (bpm == null || bpm <= 0) return;

    if (bpm < VitalThresholds.heartRateLow) {
      _startOrEscalateTimer('BPM_Low', AlertSeverity.warning);
    } else {
      _cancelTimer('BPM_Low');
    }

    if (bpm > VitalThresholds.heartRateHigh) {
      _startOrEscalateTimer('BPM_High', AlertSeverity.warning);
    } else {
      _cancelTimer('BPM_High');
    }
  }

  void _evaluateTemp(double? temp) {
    if (temp == null || temp <= 0) return;

    const metric = 'Temp';

    if (temp > VitalThresholds.tempCritical) {
      _startOrEscalateTimer(metric, AlertSeverity.critical);
    } else if (temp > VitalThresholds.tempWarning) {
      _startOrDeescalateTimer(metric, AlertSeverity.warning);
    } else {
      _cancelTimer(metric);
    }
  }

  // ── Timer management ───────────────────────────────────────────────────────

  /// Starts an onset timer for [metric] at [severity].
  ///
  /// **Escalation rule:** if a timer already runs at a *lower* severity,
  /// inherit the elapsed time so the critical alert fires sooner.
  void _startOrEscalateTimer(String metric, AlertSeverity severity) {
    if (_isInCooldown(metric)) return;

    final existingOnset = _onsetTimes[metric];

    if (existingOnset != null) {
      // A pre-alert is already running — compute remaining time.
      final elapsed   = DateTime.now().difference(existingOnset);
      final remaining = _alertOnsetDelay - elapsed;

      // Cancel existing timer (severity may have changed).
      _onsetTimers[metric]?.cancel();

      if (remaining <= Duration.zero) {
        _onAlertFired(metric, _buildAlert(metric, severity: severity));
        return;
      }

      // Restart with remaining duration (inherited elapsed).
      _onsetTimers[metric] = Timer(
        remaining,
        () => _onAlertFired(metric, _buildAlert(metric, severity: severity)),
      );
    } else {
      // Fresh onset.
      _onsetTimes[metric] = DateTime.now();
      _onsetTimers[metric] = Timer(
        _alertOnsetDelay,
        () => _onAlertFired(metric, _buildAlert(metric, severity: severity)),
      );
      _startTickTimer(); // ensure tick is running
    }
  }

  /// Starts/restarts an onset timer at a *lower* severity (de-escalation).
  /// Always resets to zero — the severe condition cleared.
  void _startOrDeescalateTimer(String metric, AlertSeverity severity) {
    if (_isInCooldown(metric)) return;

    final hadHigherSeverity = _onsetTimes.containsKey(metric);

    // Cancel existing timer regardless — start fresh for milder condition.
    _onsetTimers[metric]?.cancel();
    _onsetTimes[metric] = DateTime.now();

    _onsetTimers[metric] = Timer(
      _alertOnsetDelay,
      () => _onAlertFired(metric, _buildAlert(metric, severity: severity)),
    );

    if (!hadHigherSeverity) {
      _startTickTimer();
    }
  }

  void _cancelTimer(String metric) {
    _onsetTimers[metric]?.cancel();
    _onsetTimers.remove(metric);
    _onsetTimes.remove(metric);

    // Also clear any active alert for this metric that has since normalised.
    _activeAlerts.removeWhere((a) => a.metrics.contains(metric));

    if (_onsetTimes.isEmpty) {
      _tickTimer?.cancel();
      _tickTimer = null;
    }
  }

  void _onAlertFired(String metric, VitalAlert alert) {
    _onsetTimers.remove(metric);
    // Keep _onsetTimes entry — needed for cooldown tracking.

    // Remove any pre-existing alert for this metric before adding the new one.
    _activeAlerts.removeWhere((a) => a.metrics.contains(metric));
    _activeAlerts.add(alert);

    // Sort: critical first, then warning.
    _activeAlerts.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    _markCooldown(metric);

    if (_onsetTimes.isEmpty || _onsetTimers.isEmpty) {
      _tickTimer?.cancel();
      _tickTimer = null;
    }

    _emitCurrentState();
  }

  // ── Immediate (no-delay) alert ─────────────────────────────────────────────

  void _emitImmediateAlert(String deviceStatus) {
    final now = DateTime.now();

    final (message, severity) = switch (deviceStatus) {
      'FALL_DETECTED'       => ('⚠ Fall Detected!',             AlertSeverity.critical),
      'EMERGENCY_BUTTON'    => ('🆘 Emergency Button Pressed!', AlertSeverity.critical),
      'EMERGENCY_NO_PULSE'  => ('🚨 No Pulse Detected!',        AlertSeverity.critical),
      _                     => ('Emergency: $deviceStatus',      AlertSeverity.critical),
    };

    final alert = VitalAlert(
      metrics:   [deviceStatus],
      message:   message,
      severity:  severity,
      timestamp: now,
      rawValues: Map.of(_lastKnownValues),
    );

    _activeAlerts.removeWhere((a) => a.metrics.contains(deviceStatus));
    _activeAlerts.insert(0, alert); // Emergency always goes first
    _emitCurrentState();
  }

  // ── Tick timer ─────────────────────────────────────────────────────────────

  void _startTickTimer() {
    if (_tickTimer != null) return; // already running
    _tickTimer = Timer.periodic(
      const Duration(seconds: 1),
      _onTick,
    );
  }

  void _onTick(Timer t) {
    if (_onsetTimes.isEmpty) {
      t.cancel();
      _tickTimer = null;
      return;
    }
    _emitCurrentState();
  }

  // ── Stale watchdog ─────────────────────────────────────────────────────────

  void _resetStaleWatchdog() {
    _staleWatchdog?.cancel();
    _staleWatchdog = Timer(_staleTimeout, _onStale);
  }

  void _onStale() {
    // No data received for 60 s — cancel everything and return to normal.
    for (final t in _onsetTimers.values) {
      t.cancel();
    }
    _onsetTimers.clear();
    _onsetTimes.clear();
    _tickTimer?.cancel();
    _tickTimer = null;
    _activeAlerts.clear();
    _emitCurrentState();
  }

  // ── Cooldown helpers ───────────────────────────────────────────────────────

  bool _isInCooldown(String metric) {
    final end = _cooldownEnds[metric];
    if (end == null) return false;
    return DateTime.now().isBefore(end);
  }

  void _markCooldown(String metric) {
    _cooldownEnds[metric] =
        DateTime.now().add(_alertCooldownDuration);

    // Schedule onset restart after cooldown if value is still abnormal.
    // evaluate() is called continuously by the real-time stream, so no
    // explicit restart is needed — the next evaluate() call will re-start
    // the timer once cooldown expires.
  }

  // ── Alert builder ──────────────────────────────────────────────────────────

  /// Builds a [VitalAlert] from the last known values at fire-time.
  VitalAlert _buildAlert(String metric, {AlertSeverity? severity}) {
    final now  = DateTime.now();
    final vals = Map<String, dynamic>.of(_lastKnownValues);

    return switch (metric) {
      'SpO2' => VitalAlert(
          metrics:   ['SpO2'],
          message:   severity == AlertSeverity.critical
              ? 'Critical Oxygen Level: ${_lastKnownValues['spo2']?.toInt() ?? '--'}%'
              : 'Low Oxygen Level: ${_lastKnownValues['spo2']?.toInt() ?? '--'}%',
          severity:  severity ?? AlertSeverity.warning,
          timestamp: now,
          rawValues: vals,
        ),
      'BPM_Low' => VitalAlert(
          metrics:   ['Heart Rate'],
          message:   'Bradycardia: ${_lastKnownValues['bpm']?.toInt() ?? '--'} bpm',
          severity:  AlertSeverity.warning,
          timestamp: now,
          rawValues: vals,
        ),
      'BPM_High' => VitalAlert(
          metrics:   ['Heart Rate'],
          message:   'Tachycardia: ${_lastKnownValues['bpm']?.toInt() ?? '--'} bpm',
          severity:  AlertSeverity.warning,
          timestamp: now,
          rawValues: vals,
        ),
      'Temp' => VitalAlert(
          metrics:   ['Temperature'],
          message:   severity == AlertSeverity.critical
              ? 'High Fever: ${_lastKnownValues['temp']?.toStringAsFixed(1) ?? '--'}°C'
              : 'Fever: ${_lastKnownValues['temp']?.toStringAsFixed(1) ?? '--'}°C',
          severity:  severity ?? AlertSeverity.warning,
          timestamp: now,
          rawValues: vals,
        ),
      _ => VitalAlert(
          metrics:   [metric],
          message:   'Abnormal $metric detected',
          severity:  severity ?? AlertSeverity.warning,
          timestamp: now,
          rawValues: vals,
        ),
    };
  }

  // ── Emit ───────────────────────────────────────────────────────────────────

  void _emitCurrentState() {
    if (_ctrl.isClosed) return;

    // Compute pre-alert from the metric with the most progress.
    PreAlertInfo? preAlert;
    if (_onsetTimes.isNotEmpty && _activeAlerts.isEmpty) {
      // Find the onset that started earliest (most progress).
      final earliest = _onsetTimes.entries.reduce(
        (a, b) => a.value.isBefore(b.value) ? a : b,
      );
      final elapsed = DateTime.now().difference(earliest.value);

      // Determine severity label from current metric.
      final metricLabel = switch (earliest.key) {
        'SpO2'     => 'SpO2',
        'BPM_Low'  => 'Heart Rate (Low)',
        'BPM_High' => 'Heart Rate (High)',
        'Temp'     => 'Temperature',
        _          => earliest.key,
      };

      preAlert = PreAlertInfo(
        metric:  metricLabel,
        elapsed: elapsed,
        target:  _alertOnsetDelay,
      );
    }

    final primary = _activeAlerts.isEmpty ? null : _activeAlerts.first;

    _ctrl.add(VitalAlertState(
      primaryAlert: primary,
      allAlerts:    List.unmodifiable(_activeAlerts),
      preAlert:     preAlert,
    ));
  }
}
