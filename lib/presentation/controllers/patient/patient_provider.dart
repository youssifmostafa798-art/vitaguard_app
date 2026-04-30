import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/data/repositories/patient/patient_repository.dart';
import 'package:vitaguard_app/data/models/patient/patient_models.dart';

part 'patient_provider.g.dart';

class PatientState {
  final bool isLoading;
  final String? error;
  final XRayResult? lastXRayResult;
  final String? companionCode;
  final MedicalHistory? medicalHistory;

  PatientState({
    this.isLoading = false,
    this.error,
    this.lastXRayResult,
    this.companionCode,
    this.medicalHistory,
  });

  PatientState copyWith({
    bool? isLoading,
    String? error,
    XRayResult? lastXRayResult,
    String? companionCode,
    MedicalHistory? medicalHistory,
  }) {
    return PatientState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastXRayResult: lastXRayResult ?? this.lastXRayResult,
      companionCode: companionCode ?? this.companionCode,
      medicalHistory: medicalHistory ?? this.medicalHistory,
    );
  }
}

@riverpod
class PatientController extends _$PatientController {
  PatientRepository get _repository => ref.read(patientRepositoryProvider);
  PatientRepository get repository => _repository;

  @override
  PatientState build() {
    return PatientState();
  }

  Future<bool> submitDailyReport(DailyReport report) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.submitDailyReport(report);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
      return false;
    }
  }

  Future<bool> updateMedicalHistory(MedicalHistory history) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.updateMedicalHistory(history);
      state = state.copyWith(isLoading: false, medicalHistory: history);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
      return false;
    }
  }

  Future<bool> analyzeXRay(File image, {String? patientId}) async {
    state = state.copyWith(isLoading: true, error: null, lastXRayResult: null);
    try {
      final result = await _repository.analyzeXRay(image, patientId: patientId);
      state = state.copyWith(isLoading: false, lastXRayResult: result);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
      return false;
    }
  }

  Future<void> fetchCompanionCode() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final code = await _repository.getCompanionCode();
      state = state.copyWith(isLoading: false, companionCode: code);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
    }
  }

  Future<void> fetchMedicalHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _repository.getMedicalHistory();
      state = state.copyWith(isLoading: false, medicalHistory: history);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
    }
  }

  Future<bool> regenerateCompanionCode() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final code = await _repository.regenerateCompanionCode();
      state = state.copyWith(isLoading: false, companionCode: code);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
      return false;
    }
  }
}
