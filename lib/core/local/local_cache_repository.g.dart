

part of 'local_cache_repository.dart';

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
