import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vitaguard_app/data/models/vitals/vitals_model.dart';
import 'package:vitaguard_app/data/repositories/vitals/vitals_repository.dart';

part 'vitals_controller.g.dart';

class VitalsState {
  const VitalsState({
    this.latestVitals,
    this.isLoading = false,
    this.error,
  });

  final PatientLiveVitals? latestVitals;
  final bool isLoading;
  final String? error;

  VitalsState copyWith({
    PatientLiveVitals? latestVitals,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return VitalsState(
      latestVitals: latestVitals ?? this.latestVitals,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

@riverpod
class VitalsController extends _$VitalsController {
  @override
  VitalsState build() {
    return const VitalsState();
  }

  Future<void> loadLatestVitals(String patientId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final vitals = await ref.read(vitalsRepositoryProvider).getLatestVitals(patientId);
      state = state.copyWith(latestVitals: vitals, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Stream<PatientLiveVitals> subscribeToVitals(String patientId) {
    return ref.read(vitalsRepositoryProvider).subscribeToVitals(patientId);
  }
}
