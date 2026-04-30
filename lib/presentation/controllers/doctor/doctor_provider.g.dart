// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DoctorController)
final doctorControllerProvider = DoctorControllerProvider._();

final class DoctorControllerProvider
    extends $NotifierProvider<DoctorController, DoctorState> {
  DoctorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'doctorControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$doctorControllerHash();

  @$internal
  @override
  DoctorController create() => DoctorController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DoctorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DoctorState>(value),
    );
  }
}

String _$doctorControllerHash() => r'bc70aaa61eef445c8b021a51490c404d23983203';

abstract class _$DoctorController extends $Notifier<DoctorState> {
  DoctorState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DoctorState, DoctorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DoctorState, DoctorState>,
              DoctorState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
