// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'companion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CompanionController)
final companionControllerProvider = CompanionControllerProvider._();

final class CompanionControllerProvider
    extends $NotifierProvider<CompanionController, CompanionState> {
  CompanionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'companionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$companionControllerHash();

  @$internal
  @override
  CompanionController create() => CompanionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompanionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompanionState>(value),
    );
  }
}

String _$companionControllerHash() =>
    r'1a0a0d2e8c88baaf3cfab93a6200100e2d8cc439';

abstract class _$CompanionController extends $Notifier<CompanionState> {
  CompanionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CompanionState, CompanionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CompanionState, CompanionState>,
              CompanionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
