import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vitaguard_app/data/models/companion/companion_models.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/data/repositories/companion/companion_repository.dart';

part 'companion_provider.g.dart';

class CompanionState {
  final bool isLoading;
  final String? error;
  final LinkedPatientStatus? patientStatus;
  final String? companionCode;

  CompanionState({
    this.isLoading = false,
    this.error,
    this.patientStatus,
    this.companionCode,
  });

  CompanionState copyWith({
    bool? isLoading,
    String? error,
    LinkedPatientStatus? patientStatus,
    String? companionCode,
  }) {
    return CompanionState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      patientStatus: patientStatus ?? this.patientStatus,
      companionCode: companionCode ?? this.companionCode,
    );
  }
}

@riverpod
class CompanionController extends _$CompanionController {
  CompanionRepository get _repository => ref.read(companionRepositoryProvider);

  @override
  CompanionState build() {
    return CompanionState();
  }

  Future<bool> linkPatient(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.linkPatient(code);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
      return false;
    }
  }

  Future<void> fetchPatientStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final status = await _repository.getPatientStatus();
      state = state.copyWith(isLoading: false, patientStatus: status);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
    }
  }

  Future<void> fetchLinkedPatientCode() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final code = await _repository.getLinkedPatientCode();
      state = state.copyWith(isLoading: false, companionCode: code);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
    }
  }
}
