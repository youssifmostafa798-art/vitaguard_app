// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'facility_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FacilityController)
final facilityControllerProvider = FacilityControllerProvider._();

final class FacilityControllerProvider
    extends $NotifierProvider<FacilityController, FacilityState> {
  FacilityControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'facilityControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$facilityControllerHash();

  @$internal
  @override
  FacilityController create() => FacilityController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FacilityState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FacilityState>(value),
    );
  }
}

String _$facilityControllerHash() =>
    r'd3e15d877a4e1a55c7b7071c85fc36a14b88d8d8';

abstract class _$FacilityController extends $Notifier<FacilityState> {
  FacilityState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FacilityState, FacilityState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FacilityState, FacilityState>,
              FacilityState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
