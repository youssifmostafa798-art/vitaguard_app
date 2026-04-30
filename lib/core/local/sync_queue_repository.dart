import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:vitaguard_app/core/local/vitaguard_local_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vitaguard_app/core/utils/uuid.dart';

part 'sync_queue_repository.g.dart';

@Riverpod(keepAlive: true)
SyncQueueRepository syncQueueRepository(Ref ref) {
  return SyncQueueRepository(ref.watch(vitaGuardLocalDatabaseProvider));
}

class SyncQueueRepository {
  SyncQueueRepository(this._database);

  final VitaGuardLocalDatabase _database;

  Future<void> enqueue({
    required String operation,
    required String target,
    required Map<String, dynamic> payload,
  }) {
    return _database.into(_database.syncQueueItems).insert(
          SyncQueueItemsCompanion.insert(
            id: Uuid.v4(),
            operation: operation,
            target: target,
            payloadJson: jsonEncode(payload),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<List<SyncQueueItem>> pendingItems() {
    return (_database.select(_database.syncQueueItems)
          ..orderBy([(item) => OrderingTerm.asc(item.createdAt)]))
        .get();
  }

  Future<void> markAttemptFailed(String id, Object error) {
    return _database.transaction(() async {
      final current = await (_database.select(_database.syncQueueItems)
            ..where((item) => item.id.equals(id)))
          .getSingleOrNull();
      if (current == null) return;

      await (_database.update(_database.syncQueueItems)
          ..where((item) => item.id.equals(id)))
          .write(
        SyncQueueItemsCompanion(
          retryCount: Value(current.retryCount + 1),
          lastAttemptAt: Value(DateTime.now().toUtc()),
          lastError: Value(error.toString()),
        ),
      );
    });
  }

  Future<void> remove(String id) {
    return (_database.delete(_database.syncQueueItems)
          ..where((item) => item.id.equals(id)))
        .go();
  }
}