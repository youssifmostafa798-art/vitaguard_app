

part of 'health_provider.dart';

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HealthController)
final healthControllerProvider = HealthControllerProvider._();

final class HealthControllerProvider
    extends $NotifierProvider<HealthController, HealthState> {
  HealthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthControllerHash();

  @$internal
  @override
  HealthController create() => HealthController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthState>(value),
    );
  }
}

String _$healthControllerHash() => r'e906fc386e18840148dad2cda69fe4bad329ee73';

abstract class _$HealthController extends $Notifier<HealthState> {
  HealthState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<HealthState, HealthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HealthState, HealthState>,
              HealthState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
