

part of 'vitals_controller.dart';

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VitalsController)
final vitalsControllerProvider = VitalsControllerProvider._();

final class VitalsControllerProvider
    extends $NotifierProvider<VitalsController, VitalsState> {
  VitalsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vitalsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vitalsControllerHash();

  @$internal
  @override
  VitalsController create() => VitalsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VitalsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VitalsState>(value),
    );
  }
}

String _$vitalsControllerHash() => r'01e8bff9363ed66acbdbd7a0408a19637a53ddaa';

abstract class _$VitalsController extends $Notifier<VitalsState> {
  VitalsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<VitalsState, VitalsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VitalsState, VitalsState>,
              VitalsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}