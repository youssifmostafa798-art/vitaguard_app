

part of 'ai_chat_repository.dart';

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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