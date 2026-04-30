// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AiChatController)
final aiChatControllerProvider = AiChatControllerProvider._();

final class AiChatControllerProvider
    extends $NotifierProvider<AiChatController, AiChatState> {
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
  Override overrideWithValue(AiChatState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiChatState>(value),
    );
  }
}

String _$aiChatControllerHash() => r'48e96ba4244e6f14ac9691c413e4e9293f1635c3';

abstract class _$AiChatController extends $Notifier<AiChatState> {
  AiChatState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AiChatState, AiChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AiChatState, AiChatState>,
              AiChatState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
