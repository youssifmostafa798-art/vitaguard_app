// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers_modern.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supabaseService)
final supabaseServiceProvider = SupabaseServiceProvider._();

final class SupabaseServiceProvider
    extends
        $FunctionalProvider<SupabaseService, SupabaseService, SupabaseService>
    with $Provider<SupabaseService> {
  SupabaseServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseServiceHash();

  @$internal
  @override
  $ProviderElement<SupabaseService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseService create(Ref ref) {
    return supabaseService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseService>(value),
    );
  }
}

String _$supabaseServiceHash() => r'c2a81d858cb3ce6df869cef502282782be78462a';

@ProviderFor(vitaGuardLocalDatabase)
final vitaGuardLocalDatabaseProvider = VitaGuardLocalDatabaseProvider._();

final class VitaGuardLocalDatabaseProvider
    extends
        $FunctionalProvider<
          VitaGuardLocalDatabase,
          VitaGuardLocalDatabase,
          VitaGuardLocalDatabase
        >
    with $Provider<VitaGuardLocalDatabase> {
  VitaGuardLocalDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vitaGuardLocalDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vitaGuardLocalDatabaseHash();

  @$internal
  @override
  $ProviderElement<VitaGuardLocalDatabase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VitaGuardLocalDatabase create(Ref ref) {
    return vitaGuardLocalDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VitaGuardLocalDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VitaGuardLocalDatabase>(value),
    );
  }
}

String _$vitaGuardLocalDatabaseHash() =>
    r'0b752dbd81b3db23d2c9163edd1fa3b27a5e7d1e';

@ProviderFor(syncQueueRepository)
final syncQueueRepositoryProvider = SyncQueueRepositoryProvider._();

final class SyncQueueRepositoryProvider
    extends
        $FunctionalProvider<
          SyncQueueRepository,
          SyncQueueRepository,
          SyncQueueRepository
        >
    with $Provider<SyncQueueRepository> {
  SyncQueueRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncQueueRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncQueueRepositoryHash();

  @$internal
  @override
  $ProviderElement<SyncQueueRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SyncQueueRepository create(Ref ref) {
    return syncQueueRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncQueueRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncQueueRepository>(value),
    );
  }
}

String _$syncQueueRepositoryHash() =>
    r'815a7df384cbc095555ce6d54bc4879f0f630bb4';

@ProviderFor(localCacheRepository)
final localCacheRepositoryProvider = LocalCacheRepositoryProvider._();

final class LocalCacheRepositoryProvider
    extends
        $FunctionalProvider<
          LocalCacheRepository,
          LocalCacheRepository,
          LocalCacheRepository
        >
    with $Provider<LocalCacheRepository> {
  LocalCacheRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localCacheRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localCacheRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocalCacheRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalCacheRepository create(Ref ref) {
    return localCacheRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalCacheRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalCacheRepository>(value),
    );
  }
}

String _$localCacheRepositoryHash() =>
    r'c6c1cbc5b8324023adf1b52f087654bc51abc5dd';

@ProviderFor(offlineSyncService)
final offlineSyncServiceProvider = OfflineSyncServiceProvider._();

final class OfflineSyncServiceProvider
    extends
        $FunctionalProvider<
          OfflineSyncService,
          OfflineSyncService,
          OfflineSyncService
        >
    with $Provider<OfflineSyncService> {
  OfflineSyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineSyncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineSyncServiceHash();

  @$internal
  @override
  $ProviderElement<OfflineSyncService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OfflineSyncService create(Ref ref) {
    return offlineSyncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OfflineSyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OfflineSyncService>(value),
    );
  }
}

String _$offlineSyncServiceHash() =>
    r'e343847e5e98d0d8ab17f0d9d17a2816043e5bb6';

@ProviderFor(connectivitySyncCoordinator)
final connectivitySyncCoordinatorProvider =
    ConnectivitySyncCoordinatorProvider._();

final class ConnectivitySyncCoordinatorProvider
    extends
        $FunctionalProvider<
          ConnectivitySyncCoordinator,
          ConnectivitySyncCoordinator,
          ConnectivitySyncCoordinator
        >
    with $Provider<ConnectivitySyncCoordinator> {
  ConnectivitySyncCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivitySyncCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivitySyncCoordinatorHash();

  @$internal
  @override
  $ProviderElement<ConnectivitySyncCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConnectivitySyncCoordinator create(Ref ref) {
    return connectivitySyncCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectivitySyncCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectivitySyncCoordinator>(value),
    );
  }
}

String _$connectivitySyncCoordinatorHash() =>
    r'2d81484f5e5f7c558bfe78cc9da37ce7216cc6bc';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'5857e8d82e5309475fa6eff5c8195608b8128b04';

@ProviderFor(patientRepository)
final patientRepositoryProvider = PatientRepositoryProvider._();

final class PatientRepositoryProvider
    extends
        $FunctionalProvider<
          PatientRepository,
          PatientRepository,
          PatientRepository
        >
    with $Provider<PatientRepository> {
  PatientRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'patientRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$patientRepositoryHash();

  @$internal
  @override
  $ProviderElement<PatientRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PatientRepository create(Ref ref) {
    return patientRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PatientRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PatientRepository>(value),
    );
  }
}

String _$patientRepositoryHash() => r'a9b2cbce676f30ad2181643d674521e88c50c8d7';

@ProviderFor(doctorRepository)
final doctorRepositoryProvider = DoctorRepositoryProvider._();

final class DoctorRepositoryProvider
    extends
        $FunctionalProvider<
          DoctorRepository,
          DoctorRepository,
          DoctorRepository
        >
    with $Provider<DoctorRepository> {
  DoctorRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'doctorRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$doctorRepositoryHash();

  @$internal
  @override
  $ProviderElement<DoctorRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DoctorRepository create(Ref ref) {
    return doctorRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DoctorRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DoctorRepository>(value),
    );
  }
}

String _$doctorRepositoryHash() => r'97e472b4a357bde3c677b7f001b967caabe7c9b9';

@ProviderFor(companionRepository)
final companionRepositoryProvider = CompanionRepositoryProvider._();

final class CompanionRepositoryProvider
    extends
        $FunctionalProvider<
          CompanionRepository,
          CompanionRepository,
          CompanionRepository
        >
    with $Provider<CompanionRepository> {
  CompanionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'companionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$companionRepositoryHash();

  @$internal
  @override
  $ProviderElement<CompanionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CompanionRepository create(Ref ref) {
    return companionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompanionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompanionRepository>(value),
    );
  }
}

String _$companionRepositoryHash() =>
    r'17a5fff7c359a5039ed3f6230320cf84e209f418';

@ProviderFor(facilityRepository)
final facilityRepositoryProvider = FacilityRepositoryProvider._();

final class FacilityRepositoryProvider
    extends
        $FunctionalProvider<
          FacilityRepository,
          FacilityRepository,
          FacilityRepository
        >
    with $Provider<FacilityRepository> {
  FacilityRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'facilityRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$facilityRepositoryHash();

  @$internal
  @override
  $ProviderElement<FacilityRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FacilityRepository create(Ref ref) {
    return facilityRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FacilityRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FacilityRepository>(value),
    );
  }
}

String _$facilityRepositoryHash() =>
    r'ea65169dd01219a449f5bf6b4c7718986d4abf2f';

@ProviderFor(chatRepository)
final chatRepositoryProvider = ChatRepositoryProvider._();

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  ChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    return chatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRepository>(value),
    );
  }
}

String _$chatRepositoryHash() => r'9d434d3cd7f80470e4706fa862b535d6b591152b';

@ProviderFor(aiChatRepository)
final aiChatRepositoryProvider = AiChatRepositoryProvider._();

final class AiChatRepositoryProvider
    extends
        $FunctionalProvider<
          AiChatRepository,
          AiChatRepository,
          AiChatRepository
        >
    with $Provider<AiChatRepository> {
  AiChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiChatRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiChatRepositoryHash();

  @$internal
  @override
  $ProviderElement<AiChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AiChatRepository create(Ref ref) {
    return aiChatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiChatRepository>(value),
    );
  }
}

String _$aiChatRepositoryHash() => r'fd64b6aaeb8199eca4c53b52feee808b2c08cf11';

@ProviderFor(alertRepository)
final alertRepositoryProvider = AlertRepositoryProvider._();

final class AlertRepositoryProvider
    extends
        $FunctionalProvider<AlertRepository, AlertRepository, AlertRepository>
    with $Provider<AlertRepository> {
  AlertRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertRepositoryHash();

  @$internal
  @override
  $ProviderElement<AlertRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AlertRepository create(Ref ref) {
    return alertRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlertRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlertRepository>(value),
    );
  }
}

String _$alertRepositoryHash() => r'62c94de4450c5e9049eb9cfafb77335a96e70746';

@ProviderFor(alertRealtimeService)
final alertRealtimeServiceProvider = AlertRealtimeServiceProvider._();

final class AlertRealtimeServiceProvider
    extends
        $FunctionalProvider<
          AlertRealtimeService,
          AlertRealtimeService,
          AlertRealtimeService
        >
    with $Provider<AlertRealtimeService> {
  AlertRealtimeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertRealtimeServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertRealtimeServiceHash();

  @$internal
  @override
  $ProviderElement<AlertRealtimeService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AlertRealtimeService create(Ref ref) {
    return alertRealtimeService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlertRealtimeService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlertRealtimeService>(value),
    );
  }
}

String _$alertRealtimeServiceHash() =>
    r'3eae040aa76103f046d9360648d020706b69a17e';

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

final class AuthControllerProvider
    extends $NotifierProvider<AuthController, AuthControllerState> {
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthControllerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthControllerState>(value),
    );
  }
}

String _$authControllerHash() => r'3612ff2806a01d47bf387b281285842d1c27cb99';

abstract class _$AuthController extends $Notifier<AuthControllerState> {
  AuthControllerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AuthControllerState, AuthControllerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthControllerState, AuthControllerState>,
              AuthControllerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(PatientMedicalHistoryController)
final patientMedicalHistoryControllerProvider =
    PatientMedicalHistoryControllerProvider._();

final class PatientMedicalHistoryControllerProvider
    extends
        $AsyncNotifierProvider<
          PatientMedicalHistoryController,
          MedicalHistory
        > {
  PatientMedicalHistoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'patientMedicalHistoryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$patientMedicalHistoryControllerHash();

  @$internal
  @override
  PatientMedicalHistoryController create() => PatientMedicalHistoryController();
}

String _$patientMedicalHistoryControllerHash() =>
    r'4af903321b8d6c4d3d9d83d0d9db5143eb6b1e95';

abstract class _$PatientMedicalHistoryController
    extends $AsyncNotifier<MedicalHistory> {
  FutureOr<MedicalHistory> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MedicalHistory>, MedicalHistory>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MedicalHistory>, MedicalHistory>,
              AsyncValue<MedicalHistory>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(AiChatController)
final aiChatControllerProvider = AiChatControllerProvider._();

final class AiChatControllerProvider
    extends $NotifierProvider<AiChatController, AiChatControllerState> {
  AiChatControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiChatControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiChatControllerHash();

  @$internal
  @override
  AiChatController create() => AiChatController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiChatControllerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiChatControllerState>(value),
    );
  }
}

String _$aiChatControllerHash() => r'2a6650f3059c7534f580988c22aef5e3f8b6ab96';

abstract class _$AiChatController extends $Notifier<AiChatControllerState> {
  AiChatControllerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AiChatControllerState, AiChatControllerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiChatControllerState, AiChatControllerState>,
              AiChatControllerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
