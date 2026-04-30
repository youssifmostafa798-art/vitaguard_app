import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/core/alerts/alert_model.dart';
import 'package:vitaguard_app/core/alerts/alert_notification_service.dart';
import 'package:vitaguard_app/core/alerts/alert_realtime_service.dart';
import 'package:vitaguard_app/core/alerts/alert_repository.dart';

part 'alert_center_provider.g.dart';

class AlertCenterState {
  final List<AppAlert> alerts;
  final bool isLoading;
  final String? error;
  final bool hasRealtimeSubscription;
  final AlertAudience? audience;

  AlertCenterState({
    this.alerts = const [],
    this.isLoading = false,
    this.error,
    this.hasRealtimeSubscription = false,
    this.audience,
  });

  List<AppAlert> get activeAlerts =>
      alerts.where((alert) => alert.isActive).toList(growable: false);
  List<AppAlert> get criticalActiveAlerts => alerts
      .where((alert) => alert.isActive && alert.isCritical)
      .toList(growable: false);

  AlertCenterState copyWith({
    List<AppAlert>? alerts,
    bool? isLoading,
    String? error,
    bool? hasRealtimeSubscription,
    AlertAudience? audience,
  }) {
    return AlertCenterState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasRealtimeSubscription:
          hasRealtimeSubscription ?? this.hasRealtimeSubscription,
      audience: audience ?? this.audience,
    );
  }
}

@Riverpod(keepAlive: true)
class AlertController extends _$AlertController {
  final AlertRealtimeService _realtime = AlertRealtimeService();
  final AlertNotificationService _notifications =
      AlertNotificationService.instance;
  final Connectivity _connectivity = Connectivity();
  final Map<String, String> _patientNamesById = {};
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  String? _companionPatientId;
  List<String> _doctorPatientIds = const [];
  DateTime? _lastSyncedAt;
  bool _isSyncing = false;
  bool _wasOffline = false;

  @override
  AlertCenterState build() {
    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      _realtime.clear();
    });
    return AlertCenterState();
  }

  AlertRepository get _repository => ref.read(alertRepositoryProvider);

  Future<void> bootstrapForCompanion({
    required String patientId,
    String? patientName,
  }) async {
    if (state.audience == AlertAudience.companion &&
        _companionPatientId == patientId &&
        state.hasRealtimeSubscription) {
      return;
    }

    _companionPatientId = patientId;
    _doctorPatientIds = const [];
    if (patientName != null && patientName.trim().isNotEmpty) {
      _patientNamesById[patientId] = patientName.trim();
    }

    await _bootstrap(
      audience: AlertAudience.companion,
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
    if (state.audience == AlertAudience.doctor &&
        listEquals(sortedIncoming, sortedCurrent) &&
        state.hasRealtimeSubscription) {
      return;
    }

    _companionPatientId = null;
    _doctorPatientIds = sortedIncoming;
    _patientNamesById
      ..clear()
      ..addAll(patientNamesById);

    await _bootstrap(
      audience: AlertAudience.doctor,
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
    final index = state.alerts.indexWhere((alert) => alert.id == alertId);
    if (index == -1) return;

    final current = state.alerts[index];
    final resolvedAlert = current.copyWith(
      isAcknowledged: true,
      isResolved: true,
      acknowledgedAt: DateTime.now(),
      resolvedAt: DateTime.now(),
    );

    final updatedAlerts = List<AppAlert>.from(state.alerts);
    updatedAlerts[index] = resolvedAlert;
    _sortAndSetAlerts(updatedAlerts);

    unawaited(_notifications.clearAlert(resolvedAlert));
    unawaited(_syncNotificationState());

    try {
      await _repository.acknowledgeAlert(alertId);
    } catch (e) {
      // Revert if failed
      final revertedAlerts = List<AppAlert>.from(state.alerts);
      final revertIdx = revertedAlerts.indexWhere((a) => a.id == alertId);
      if (revertIdx != -1) {
        revertedAlerts[revertIdx] = current;
        _sortAndSetAlerts(revertedAlerts);
      }
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _bootstrap({
    required AlertAudience audience,
    required Future<List<AppAlert>> Function() fetch,
    required Future<void> Function() subscribe,
  }) async {
    state = state.copyWith(isLoading: true, error: null, audience: audience);

    try {
      await _notifications.initialize();
      await _ensureConnectivityListener();
      final fetchedAlerts = await fetch();
      _sortAndSetAlerts(fetchedAlerts);
      await _syncNotificationState();
      await subscribe();
      state = state.copyWith(isLoading: false, hasRealtimeSubscription: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _sortAndSetAlerts(List<AppAlert> alerts) {
    alerts.sort((a, b) {
      final activeOrder = (b.isActive ? 1 : 0).compareTo(a.isActive ? 1 : 0);
      if (activeOrder != 0) return activeOrder;
      final severityOrder = b.severity.index.compareTo(a.severity.index);
      if (severityOrder != 0) return severityOrder;
      return b.occurredAt.compareTo(a.occurredAt);
    });
    state = state.copyWith(alerts: alerts);
    _refreshLastSyncedAt();
  }

  void _mergeIncomingAlert(AppAlert alert, {required bool fromRealtime}) {
    final index = state.alerts.indexWhere((existing) => existing.id == alert.id);
    final wasKnown = index != -1;
    final previous = wasKnown ? state.alerts[index] : null;

    if (alert.patientName.trim().isNotEmpty) {
      _patientNamesById[alert.patientId] = alert.patientName;
    }

    final updatedAlerts = List<AppAlert>.from(state.alerts);
    if (wasKnown) {
      updatedAlerts[index] = alert.copyWith(
        patientName: alert.patientName.isNotEmpty
            ? alert.patientName
            : previous?.patientName,
      );
    } else {
      updatedAlerts.add(alert);
    }

    _sortAndSetAlerts(updatedAlerts);

    if (alert.isResolved) {
      unawaited(_notifications.clearAlert(alert));
      unawaited(_syncNotificationState());
    } else if (fromRealtime && !wasKnown && alert.isActive) {
      unawaited(_notifications.presentAlert(alert));
    }
  }

  void _refreshLastSyncedAt() {
    if (state.alerts.isEmpty) {
      _lastSyncedAt = null;
      return;
    }
    _lastSyncedAt = state.alerts
        .map((alert) => alert.lastSeenAt)
        .reduce((latest, next) => latest.isAfter(next) ? latest : next);
  }

  Future<void> _ensureConnectivityListener() async {
    if (_connectivitySubscription != null) return;
    final initial = await _connectivity.checkConnectivity();
    _wasOffline = initial.contains(ConnectivityResult.none);
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
          final isOffline = results.contains(ConnectivityResult.none);
          if (_wasOffline && !isOffline) unawaited(_resync());
          _wasOffline = isOffline;
        });
  }

  Future<void> _resync() async {
    if (_isSyncing || state.audience == null) return;
    _isSyncing = true;
    try {
      final since = _lastSyncedAt?.subtract(const Duration(minutes: 1));
      final refreshedAlerts = switch (state.audience!) {
        AlertAudience.companion =>
          _companionPatientId == null
              ? <AppAlert>[]
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
      state = state.copyWith(error: e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  void _handleRealtimeStatus(RealtimeSubscribeStatus status, Object? error) {
    if (status == RealtimeSubscribeStatus.subscribed) {
      unawaited(_resync());
    } else if (status == RealtimeSubscribeStatus.channelError ||
        status == RealtimeSubscribeStatus.timedOut) {
      state = state.copyWith(
        error: error?.toString() ?? 'Realtime alert subscription failed.',
      );
    }
  }

  Future<void> _syncNotificationState() async {
    final critical = state.criticalActiveAlerts;
    if (critical.isNotEmpty) {
      await _notifications.presentAlert(critical.first);
    } else if (state.activeAlerts.isEmpty) {
      await _notifications.clearAll();
    }
  }

  Future<void> onAppResumed() => _resync();
}