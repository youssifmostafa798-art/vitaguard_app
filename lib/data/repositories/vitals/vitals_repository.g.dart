

part of 'vitals_repository.dart';

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(vitalsRepository)
final vitalsRepositoryProvider = VitalsRepositoryProvider._();

final class VitalsRepositoryProvider
    extends
        $FunctionalProvider<
          VitalsRepository,
          VitalsRepository,
          VitalsRepository
        >
    with $Provider<VitalsRepository> {
  VitalsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vitalsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vitalsRepositoryHash();

  @$internal
  @override
  $ProviderElement<VitalsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VitalsRepository create(Ref ref) {
    return vitalsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VitalsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VitalsRepository>(value),
    );
  }
}

String _$vitalsRepositoryHash() => r'04f7146c6b99de0c350b5239f453d11b4b4e54ba';
