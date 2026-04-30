// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PatientController)
final patientControllerProvider = PatientControllerProvider._();

final class PatientControllerProvider
    extends $NotifierProvider<PatientController, PatientState> {
  PatientControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'patientControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$patientControllerHash();

  @$internal
  @override
  PatientController create() => PatientController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PatientState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PatientState>(value),
    );
  }
}

String _$patientControllerHash() => r'cd87066ca2816a796d6ea289ac3dfd193de1835d';

abstract class _$PatientController extends $Notifier<PatientState> {
  PatientState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PatientState, PatientState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PatientState, PatientState>,
              PatientState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
