import 'dart:convert';
import 'package:vitaguard_app/core/local/sync_queue_repository.dart';
import 'package:vitaguard_app/core/local/vitaguard_local_database.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';

class OfflineSyncService {
  OfflineSyncService({
    required SupabaseService supabase,
    required SyncQueueRepository syncQueue,
  }) : _supabase = supabase,
       _syncQueue = syncQueue;

  final SupabaseService _supabase;
  final SyncQueueRepository _syncQueue;

  Future<OfflineSyncResult> replayPendingWrites() async {
    final pending = await _syncQueue.pendingItems();
    var synced = 0;
    var failed = 0;

    for (final item in pending) {
      try {
        await _replay(item);
        await _syncQueue.remove(item.id);
        synced += 1;
      } catch (error) {
        failed += 1;
        await _syncQueue.markAttemptFailed(item.id, error);
      }
    }

    return OfflineSyncResult(
      attempted: pending.length,
      synced: synced,
      failed: failed,
    );
  }

  Future<void> _replay(SyncQueueItem item) async {
    final payload = Map<String, dynamic>.from(
      jsonDecode(item.payloadJson) as Map,
    );

    switch (item.operation) {
      case 'insert':
        await _supabase.table(item.target).insert(payload);
      case 'upsert':
        await _supabase.table(item.target).upsert(payload);
      case 'function':
        await _supabase.invokeFunction(item.target, body: payload);
      case 'rpc':
        await _supabase.rpc<Object?>(item.target, params: payload);
      default:
        throw StateError('Unsupported sync operation: ${item.operation}');
    }
  }
}

class OfflineSyncResult {
  const OfflineSyncResult({
    required this.attempted,
    required this.synced,
    required this.failed,
  });

  final int attempted;
  final int synced;
  final int failed;

  bool get hasFailures => failed > 0;
}
