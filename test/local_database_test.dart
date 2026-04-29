import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitaguard_app/core/local/local_cache_repository.dart';
import 'package:vitaguard_app/core/local/sync_queue_repository.dart';
import 'package:vitaguard_app/core/local/vitaguard_local_database.dart';

void main() {
  late VitaGuardLocalDatabase database;

  setUp(() {
    database = VitaGuardLocalDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('local cache preserves Supabase payload keys verbatim', () async {
    final cache = LocalCacheRepository(database);

    await cache.cachePatient({
      'id': 'patient-1',
      'gender': 'female',
      'age': 32,
      'assigned_doctor_id': 'doctor-1',
      'updated_at': '2026-04-30T08:00:00.000Z',
    });

    final row = await cache.getPatient('patient-1');

    expect(row?['assigned_doctor_id'], 'doctor-1');
    expect(row?['gender'], 'female');
    expect(row?['age'], 32);
  });

  test('sync queue records pending writes without touching Supabase', () async {
    final queue = SyncQueueRepository(database);

    await queue.enqueue(
      operation: 'insert',
      target: 'patient_daily_reports',
      payload: {
        'patient_id': 'patient-1',
        'heart_rate': 88,
      },
    );

    final pending = await queue.pendingItems();

    expect(pending, hasLength(1));
    expect(pending.single.operation, 'insert');
    expect(pending.single.target, 'patient_daily_reports');
    expect(pending.single.payloadJson, contains('heart_rate'));
  });

  test('sync queue increments retry metadata after failed attempt', () async {
    final queue = SyncQueueRepository(database);

    await queue.enqueue(
      operation: 'upsert',
      target: 'patient_medical_history',
      payload: {'patient_id': 'patient-1'},
    );
    final item = (await queue.pendingItems()).single;

    await queue.markAttemptFailed(item.id, StateError('offline'));

    final failed = (await queue.pendingItems()).single;
    expect(failed.retryCount, 1);
    expect(failed.lastError, contains('offline'));
    expect(failed.lastAttemptAt, isNotNull);
  });
}
