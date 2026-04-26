import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/core/alerts/alert_model.dart';
import 'package:vitaguard_app/core/alerts/alert_notification_service.dart';
import 'package:vitaguard_app/core/alerts/alert_realtime_service.dart';
import 'package:vitaguard_app/core/alerts/alert_repository.dart';

class AlertCenterProvider with ChangeNotifier {
  final AlertRepository _repository = AlertRepository();
  final AlertRealtimeService _realtime = AlertRealtimeService();
  final AlertNotificationService _notifications =
      AlertNotificationService.instance;
  final Connectivity _connectivity = Connectivity();

  final List<AppAlert> _alerts = [];
  final Map<String, String> _patientNamesById = {};

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isLoading = false;
  bool _hasRealtimeSubscription = false;
  bool _isSyncing = false;
  bool _wasOffline = false;
  String? _error;
  AlertAudience? _audience;
  String? _companionPatientId;
  List<String> _doctorPatientIds = const [];
  DateTime? _lastSyncedAt;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AppAlert> get alerts => List.unmodifiable(_alerts);
  List<AppAlert> get activeAlerts =>
      _alerts.where((alert) => alert.isActive).toList(growable: false);
  List<AppAlert> get criticalActiveAlerts => _alerts
      .where((alert) => alert.isActive && alert.isCritical)
      .toList(growable: false);

  Future<void> bootstrapForCompanion({
    required String patientId,
    String? patientName,
  }) async {
    final alreadyBootstrapped =
        _audience == AlertAudience.companion &&
        _companionPatientId == patientId &&
        _hasRealtimeSubscription;
    if (alreadyBootstrapped) {
      return;
    }

    _audience = AlertAudience.companion;
    _companionPatientId = patientId;
    _doctorPatientIds = const [];
    if (patientName != null && patientName.trim().isNotEmpty) {
      _patientNamesById[patientId] = patientName.trim();
    }

    await _bootstrap(
      fetch: () => _repository.fetchAlertsForCompanion(
        patientId: patientId,
        patientName: _patientNamesById[patientId],
      ),
      subscribe: () => _realtime.subscribeForCompanion(
        patientId: patientId,
        fallbackPatientName: _patientNamesById[patientId],
        onAlert: (alert) => _mergeIncomingAlert(alert, fromRealtime: true),
        onStatus: _handleRealtimeStatus,
      ),
    );
  }

  Future<void> bootstrapForDoctor({
    required List<String> patientIds,
    Map<String, String> patientNamesById = const {},
  }) async {
    final sortedIncoming = [...patientIds]..sort();
    final sortedCurrent = [..._doctorPatientIds]..sort();
    final alreadyBootstrapped =
        _audience == AlertAudience.doctor &&
        listEquals(sortedIncoming, sortedCurrent) &&
        _hasRealtimeSubscription;
    if (alreadyBootstrapped) {
      return;
    }

    _audience = AlertAudience.doctor;
    _companionPatientId = null;
    _doctorPatientIds = sortedIncoming;
    _patientNamesById
      ..clear()
      ..addAll(patientNamesById);

    await _bootstrap(
      fetch: () => _repository.fetchAlertsForDoctor(
        patientIds: patientIds,
        patientNamesById: patientNamesById,
      ),
      subscribe: () => _realtime.subscribeForDoctor(
        patientIds: patientIds,
        patientNamesById: patientNamesById,
        onAlert: (alert) => _mergeIncomingAlert(alert, fromRealtime: true),
        onStatus: _handleRealtimeStatus,
      ),
    );
  }

  Future<void> acknowledgeAlert(String alertId) async {
    final index = _alerts.indexWhere((alert) => alert.id == alertId);
    if (index == -1) {
      return;
    }

    final current = _alerts[index];
    final resolvedAlert = current.copyWith(
      isAcknowledged: true,
      isResolved: true,
      acknowledgedAt: DateTime.now(),
      resolvedAt: DateTime.now(),
    );

    _alerts[index] = resolvedAlert;
    _sortAlerts();
    notifyListeners();
    unawaited(_notifications.clearAlert(resolvedAlert));
    unawaited(_syncNotificationState());

    try {
      await _repository.acknowledgeAlert(alertId);
    } catch (e) {
      _alerts[index] = current;
      _sortAlerts();
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> onAppResumed() async {
    await _resync();
  }

  Future<void> _bootstrap({
    required Future<List<AppAlert>> Function() fetch,
    required Future<void> Function() subscribe,
  }) async {
    _isLoading = true;
    _error = null;
    _hasRealtimeSubscription = false;
    notifyListeners();

    try {
      await _notifications.initialize();
      await _ensureConnectivityListener();
      final fetchedAlerts = await fetch();
      _replaceAlerts(fetchedAlerts);
      await _syncNotificationState();
      await subscribe();
      _hasRealtimeSubscription = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _resync() async {
    if (_isSyncing || _audience == null) {
      return;
    }

    _isSyncing = true;
    try {
      final since = _lastSyncedAt?.subtract(const Duration(minutes: 1));
      final refreshedAlerts = switch (_audience!) {
        AlertAudience.companion =>
          _companionPatientId == null
              ? const <AppAlert>[]
              : await _repository.fetchAlertsForCompanion(
                  patientId: _companionPatientId!,
                  patientName: _patientNamesById[_companionPatientId!],
                  since: since,
                ),
        AlertAudience.doctor => await _repository.fetchAlertsForDoctor(
          patientIds: _doctorPatientIds,
          patientNamesById: _patientNamesById,
          since: since,
        ),
      };

      for (final alert in refreshedAlerts) {
        _mergeIncomingAlert(alert, fromRealtime: false);
      }
      await _syncNotificationState();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isSyncing = false;
    }
  }

  void _replaceAlerts(List<AppAlert> alerts) {
    _alerts
      ..clear()
      ..addAll(alerts);
    _sortAlerts();
    _refreshLastSyncedAt();
  }

  void _mergeIncomingAlert(AppAlert alert, {required bool fromRealtime}) {
    final index = _alerts.indexWhere((existing) => existing.id == alert.id);
    final wasKnown = index != -1;
    final previous = wasKnown ? _alerts[index] : null;

    if (alert.patientName.trim().isNotEmpty) {
      _patientNamesById[alert.patientId] = alert.patientName;
    }

    if (wasKnown) {
      _alerts[index] = alert.copyWith(
        patientName: alert.patientName.isNotEmpty
            ? alert.patientName
            : previous?.patientName,
      );
    } else {
      _alerts.add(alert);
    }

    _sortAlerts();
    _refreshLastSyncedAt();
    notifyListeners();

    if (alert.isResolved) {
      unawaited(_notifications.clearAlert(alert));
      unawaited(_syncNotificationState());
      return;
    }

    if (fromRealtime && !wasKnown && alert.isActive) {
      unawaited(_notifications.presentAlert(alert));
    }
  }

  void _sortAlerts() {
    _alerts.sort((a, b) {
      final activeOrder = (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0);
      if (activeOrder != 0) return activeOrder;

      final severityOrder = b.severity.index.compareTo(a.severity.index);
      if (severityOrder != 0) return severityOrder;

      return b.occurredAt.compareTo(a.occurredAt);
    });
  }

  void _refreshLastSyncedAt() {
    if (_alerts.isEmpty) {
      _lastSyncedAt = null;
      return;
    }

    _lastSyncedAt = _alerts
        .map((alert) => alert.lastSeenAt)
        .reduce((latest, next) => latest.isAfter(next) ? latest : next);
  }

  Future<void> _ensureConnectivityListener() async {
    if (_connectivitySubscription != null) {
      return;
    }

    final initial = await _connectivity.checkConnectivity();
    _wasOffline = initial.contains(ConnectivityResult.none);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final isOffline = results.contains(ConnectivityResult.none);
      if (_wasOffline && !isOffline) {
        unawaited(_resync());
      }
      _wasOffline = isOffline;
    });
  }

  void _handleRealtimeStatus(RealtimeSubscribeStatus status, Object? error) {
    if (status == RealtimeSubscribeStatus.subscribed) {
      unawaited(_resync());
      return;
    }

    if (status == RealtimeSubscribeStatus.channelError ||
        status == RealtimeSubscribeStatus.timedOut) {
      _error = error?.toString() ?? 'Realtime alert subscription failed.';
      notifyListeners();
    }
  }

  Future<void> _syncNotificationState() async {
    final critical = criticalActiveAlerts;
    if (critical.isNotEmpty) {
      await _notifications.presentAlert(critical.first);
      return;
    }

    if (activeAlerts.isEmpty) {
      await _notifications.clearAll();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    unawaited(_realtime.clear());
    super.dispose();
  }
}
