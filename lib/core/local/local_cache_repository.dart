import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:vitaguard_app/core/local/vitaguard_local_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_cache_repository.g.dart';

@Riverpod(keepAlive: true)
LocalCacheRepository localCacheRepository(Ref ref) {
  return LocalCacheRepository(ref.watch(vitaGuardLocalDatabaseProvider));
}

class LocalCacheRepository {
  LocalCacheRepository(this._database);

  final VitaGuardLocalDatabase _database;

  Future<void> cacheProfile(Map<String, dynamic> row) {
    final id = _requiredId(row, 'profiles');
    return _database.into(_database.cachedProfiles).insertOnConflictUpdate(
          CachedProfilesCompanion.insert(
            id: id,
            payloadJson: jsonEncode(row),
            cachedAt: DateTime.now().toUtc(),
            serverUpdatedAt: Value(_serverUpdatedAt(row)),
          ),
        );
  }

  Future<Map<String, dynamic>?> getProfile(String id) async {
    final row = await (_database.select(_database.cachedProfiles)
          ..where((profile) => profile.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _decode(row.payloadJson);
  }

  Future<void> cachePatient(Map<String, dynamic> row) {
    final id = _requiredId(row, 'patients');
    return _database.into(_database.cachedPatients).insertOnConflictUpdate(
          CachedPatientsCompanion.insert(
            id: id,
            payloadJson: jsonEncode(row),
            cachedAt: DateTime.now().toUtc(),
            serverUpdatedAt: Value(_serverUpdatedAt(row)),
          ),
        );
  }

  Future<Map<String, dynamic>?> getPatient(String id) async {
    final row = await (_database.select(_database.cachedPatients)
          ..where((patient) => patient.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _decode(row.payloadJson);
  }

  Future<void> cacheMedicalHistory({
    required String patientId,
    required Map<String, dynamic> row,
  }) {
    return _database
        .into(_database.cachedPatientMedicalHistories)
        .insertOnConflictUpdate(
          CachedPatientMedicalHistoriesCompanion.insert(
            patientId: patientId,
            payloadJson: jsonEncode(row),
            cachedAt: DateTime.now().toUtc(),
            serverUpdatedAt: Value(_serverUpdatedAt(row)),
          ),
        );
  }

  Future<Map<String, dynamic>?> getMedicalHistory(String patientId) async {
    final row = await (_database.select(
      _database.cachedPatientMedicalHistories,
    )..where((history) => history.patientId.equals(patientId)))
        .getSingleOrNull();
    return row == null ? null : _decode(row.payloadJson);
  }

  Future<void> recordConflict({
    required String target,
    required Map<String, dynamic> localPayload,
    required Map<String, dynamic> serverPayload,
    required String reason,
  }) {
    final id =
        '$target:${DateTime.now().toUtc().microsecondsSinceEpoch.toString()}';
    return _database.into(_database.syncConflicts).insert(
          SyncConflictsCompanion.insert(
            id: id,
            target: target,
            localPayloadJson: jsonEncode(localPayload),
            serverPayloadJson: jsonEncode(serverPayload),
            reason: reason,
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<List<SyncConflict>> unresolvedConflicts() {
    return (_database.select(_database.syncConflicts)
          ..where((conflict) => conflict.resolved.equals(false))
          ..orderBy([(conflict) => OrderingTerm.desc(conflict.createdAt)]))
        .get();
  }

  String _requiredId(Map<String, dynamic> row, String tableName) {
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) {
      throw StateError('Cannot cache $tableName row without id.');
    }
    return id;
  }

  DateTime? _serverUpdatedAt(Map<String, dynamic> row) {
    final raw = row['updated_at'] ?? row['last_seen_at'] ?? row['created_at'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toUtc();
  }

  Map<String, dynamic> _decode(String payloadJson) {
    return Map<String, dynamic>.from(jsonDecode(payloadJson) as Map);
  }
}