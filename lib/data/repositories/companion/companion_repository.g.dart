// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'companion_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
