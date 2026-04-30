// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_center_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AlertController)
final alertControllerProvider = AlertControllerProvider._();

final class AlertControllerProvider
    extends $NotifierProvider<AlertController, AlertCenterState> {
  AlertControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertControllerHash();

  @$internal
  @override
  AlertController create() => AlertController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlertCenterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlertCenterState>(value),
    );
  }
}

String _$alertControllerHash() => r'ddc3c0af378b848d7bfb2acdcb0e92499c86a09d';

abstract class _$AlertController extends $Notifier<AlertCenterState> {
  AlertCenterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AlertCenterState, AlertCenterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AlertCenterState, AlertCenterState>,
              AlertCenterState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
