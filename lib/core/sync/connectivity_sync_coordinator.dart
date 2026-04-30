import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vitaguard_app/core/sync/offline_sync_service.dart';

class ConnectivitySyncCoordinator {
  ConnectivitySyncCoordinator({
    required OfflineSyncService offlineSyncService,
    Connectivity? connectivity,
  }) : _offlineSyncService = offlineSyncService,
       _connectivity = connectivity ?? Connectivity();

  final OfflineSyncService _offlineSyncService;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _wasOffline = false;
  bool _isSyncing = false;

  Future<void> start() async {
    if (_subscription != null) return;

    final initial = await _connectivity.checkConnectivity();
    _wasOffline = initial.contains(ConnectivityResult.none);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      if (_wasOffline && !isOffline) {
        unawaited(syncNow());
      }
      _wasOffline = isOffline;
    });
  }

  Future<OfflineSyncResult?> syncNow() async {
    if (_isSyncing) return null;
    _isSyncing = true;
    try {
      return await _offlineSyncService.replayPendingWrites();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
