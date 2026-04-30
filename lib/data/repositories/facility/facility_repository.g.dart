

part of 'facility_repository.dart';

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
