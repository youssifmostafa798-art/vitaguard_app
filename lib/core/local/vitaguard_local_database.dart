import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'vitaguard_local_database.g.dart';

class CachedProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedPatients extends Table {
  TextColumn get id => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedPatientDailyReports extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedPatientMedicalHistories extends Table {
  TextColumn get patientId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {patientId};
}

class CachedAiConversations extends Table {
  TextColumn get id => text()();
  TextColumn get ownerUserId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedAiMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get ownerUserId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedConversations extends Table {
  TextColumn get id => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedPatientLiveVitals extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get recordedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedMedicalAlerts extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedFacilityOffers extends Table {
  TextColumn get id => text()();
  TextColumn get facilityId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedFacilityAppointments extends Table {
  TextColumn get id => text()();
  TextColumn get facilityId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedXrayResults extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueueItems extends Table {
  TextColumn get id => text()();
  TextColumn get operation => text()();
  TextColumn get target => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncConflicts extends Table {
  TextColumn get id => text()();
  TextColumn get target => text()();
  TextColumn get localPayloadJson => text()();
  TextColumn get serverPayloadJson => text()();
  TextColumn get reason => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get resolved => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    CachedProfiles,
    CachedPatients,
    CachedPatientDailyReports,
    CachedPatientMedicalHistories,
    CachedAiConversations,
    CachedAiMessages,
    CachedConversations,
    CachedMessages,
    CachedPatientLiveVitals,
    CachedMedicalAlerts,
    CachedFacilityOffers,
    CachedFacilityAppointments,
    CachedXrayResults,
    SyncQueueItems,
    SyncConflicts,
  ],
)
class VitaGuardLocalDatabase extends _$VitaGuardLocalDatabase {
  VitaGuardLocalDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'vitaguard_local'));

  @override
  int get schemaVersion => 1;
}
