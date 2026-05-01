import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/data/repositories/facility/facility_repository.dart';

part 'facility_provider.g.dart';

class FacilityState {
  final bool isLoading;
  final String? error;
  final List<dynamic> appointments;

  FacilityState({
    this.isLoading = false,
    this.error,
    this.appointments = const [],
  });

  FacilityState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? appointments,
  }) {
    return FacilityState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      appointments: appointments ?? this.appointments,
    );
  }
}

@riverpod
class FacilityController extends _$FacilityController {
  FacilityRepository get _repository => ref.read(facilityRepositoryProvider);

  @override
  FacilityState build() {
    // Keep alive for session: sets state after async Supabase calls.
    ref.keepAlive();
    return FacilityState();
  }

  Future<bool> uploadMedicalTest({
    String? patientId,
    String? patientPhone,
    required String testType,
    required String filePath,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.uploadMedicalTest(
        patientId: patientId,
        patientPhone: patientPhone,
        testType: testType,
        filePath: filePath,
        notes: notes,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
      return false;
    }
  }

  Future<void> fetchAppointments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apps = await _repository.getAppointments();
      state = state.copyWith(isLoading: false, appointments: apps);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
    }
  }
}
