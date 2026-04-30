import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:vitaguard_app/data/repositories/doctor/doctor_repository.dart';

part 'doctor_provider.g.dart';

class DoctorState {
  final bool isLoading;
  final String? error;
  final List<dynamic> assignedPatients;
  final String verificationStatus;
  final List<Map<String, dynamic>> dailyReports;

  DoctorState({
    this.isLoading = false,
    this.error,
    this.assignedPatients = const [],
    this.verificationStatus = 'pending',
    this.dailyReports = const [],
  });

  DoctorState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? assignedPatients,
    String? verificationStatus,
    List<Map<String, dynamic>>? dailyReports,
  }) {
    return DoctorState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      assignedPatients: assignedPatients ?? this.assignedPatients,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      dailyReports: dailyReports ?? this.dailyReports,
    );
  }
}

@riverpod
class DoctorController extends _$DoctorController {
  DoctorRepository get _repository => ref.read(doctorRepositoryProvider);
  SupabaseRealtimeSubscription? _reportsChannel;

  @override
  DoctorState build() {
    ref.onDispose(() {
      _reportsChannel?.unsubscribe();
    });
    return DoctorState();
  }

  Future<void> fetchAssignedPatients() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final patients = await _repository.getAssignedPatients();
      state = state.copyWith(isLoading: false, assignedPatients: patients);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
    }
  }

  Future<bool> sendFeedback({
    required String patientId,
    required String feedbackText,
    String? xrayResultId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.sendFeedback(
        patientId: patientId,
        feedbackText: feedbackText,
        xrayResultId: xrayResultId,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
      return false;
    }
  }

  Future<void> fetchVerificationStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final statusData = await _repository.getVerificationStatus();
      state = state.copyWith(
        isLoading: false,
        verificationStatus: statusData['verificationStatus'] ?? 'pending',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
    }
  }

  Future<bool> uploadMedicalReport({
    required String patientPhone,
    required String patientName,
    required String description,
    File? imageFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.uploadMedicalReport(
        patientPhone: patientPhone,
        patientName: patientName,
        description: description,
        imageFile: imageFile,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
      return false;
    }
  }

  Future<void> fetchAllDailyReports() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reports = await _repository.getAllAssignedPatientsDailyReports();
      state = state.copyWith(isLoading: false, dailyReports: reports);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
    }
  }

  void listenToLiveVitals() {
    if (_reportsChannel != null) return;
    if (state.dailyReports.isEmpty) return;

    final ids = state.dailyReports.map((e) => e['id'] as String).toList();
    if (ids.isEmpty) return;

    _reportsChannel = _repository.subscribeToAssignedPatientsVitals(
      patientIds: ids,
      onUpdate: (record) {
        _syncReportWithLiveVitals(record);
      },
    );
  }

  void _syncReportWithLiveVitals(Map<String, dynamic> record) {
    final patientId = record['patient_id'] as String?;
    if (patientId == null) return;

    final index = state.dailyReports.indexWhere((r) => r['id'] == patientId);
    if (index == -1) return;

    final rawBpm = (record['bpm'] as num?)?.toInt() ?? 0;
    final pulse = rawBpm > 0 ? rawBpm : 0;
    final rawSpo2 = (record['spo2'] as num?)?.toInt() ?? 0;
    final ppm = rawSpo2 > 0 ? rawSpo2 : 0;
    final rawTemp = record['temperature'] as num?;
    final tempDisplay = (rawTemp != null && rawTemp > 0) ? '$rawTemp' : '--';

    final updatedReports = List<Map<String, dynamic>>.from(state.dailyReports);
    updatedReports[index] = {
      ...updatedReports[index],
      'pulse': pulse,
      'ppm': ppm,
      'temperature': tempDisplay,
      'status': _deriveStatus(pulse, ppm),
    };
    state = state.copyWith(dailyReports: updatedReports);
  }

  String _deriveStatus(int pulse, int ppm) {
    if (pulse > 100 || pulse < 55 || ppm < 90) return 'critical';
    if (pulse > 90 || pulse < 60 || ppm < 95) return 'warning';
    return 'normal';
  }
}
