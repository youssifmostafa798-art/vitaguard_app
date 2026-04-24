import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/doctor/data/alert_evaluation_engine.dart';
import 'package:vitaguard_app/doctor/data/doctor_repository.dart';
import 'package:vitaguard_app/doctor/data/vital_alert_model.dart';

class DoctorProvider with ChangeNotifier {
  final DoctorRepository _repository = DoctorRepository();

  bool _isLoading = false;
  String? _error;
  List<dynamic> _assignedPatients = [];
  List<Map<String, dynamic>> _dailyReports = [];
  RealtimeChannel? _reportsChannel;
  final AlertEvaluationEngine _alertEngine = AlertEvaluationEngine();
  List<VitalAlert> _activeAlerts = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get assignedPatients => _assignedPatients;
  String get verificationStatus => _verificationStatus;
  List<Map<String, dynamic>> get dailyReports => _dailyReports;
  List<VitalAlert> get activeAlerts => _activeAlerts;

  // ---------------------------------------------------------------------------
  // Patients
  // ---------------------------------------------------------------------------

  Future<void> fetchAssignedPatients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assignedPatients = await _repository.getAssignedPatients();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = _handleError(e);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Feedback
  // ---------------------------------------------------------------------------

  Future<bool> sendFeedback({
    required String patientId,
    required String feedbackText,
    String? xrayResultId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.sendFeedback(
        patientId: patientId,
        feedbackText: feedbackText,
        xrayResultId: xrayResultId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _handleError(e);
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Verification
  // ---------------------------------------------------------------------------

  Future<void> fetchVerificationStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final statusData = await _repository.getVerificationStatus();
      _verificationStatus = statusData['verificationStatus'] ?? 'pending';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = _handleError(e);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Medical Reports  (Problem 2)
  // ---------------------------------------------------------------------------

  /// Uploads an optional image and saves a medical report to Supabase.
  Future<bool> uploadMedicalReport({
    required String patientPhone,
    required String patientName,
    required String description,
    File? imageFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.uploadMedicalReport(
        patientPhone: patientPhone,
        patientName: patientName,
        description: description,
        imageFile: imageFile,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _handleError(e);
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Daily Reports  (Problem 4)
  // ---------------------------------------------------------------------------

  /// Fetches the most-recent daily report for each patient assigned to this doctor.
  Future<void> fetchAllDailyReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dailyReports = await _repository.getAllAssignedPatientsDailyReports();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = _handleError(e);
      notifyListeners();
    }
  }

  /// Starts a realtime subscription to update daily reports as new vitals arrive.
  void listenToLiveVitals() {
    if (_reportsChannel != null) return;
    if (_dailyReports.isEmpty) return;

    final ids = _dailyReports.map((e) => e['id'] as String).toList();
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

    final index = _dailyReports.indexWhere((r) => r['id'] == patientId);
    if (index != -1) {
      final pulse = (record['bpm'] as num?)?.toInt() ?? 0;
      final ppm = (record['spo2'] as num?)?.toInt() ?? 0;

      // Update the existing report in memory
      _dailyReports[index] = {
        ..._dailyReports[index],
        'pulse': pulse,
        'ppm': ppm,
        'temperature': '${record['temperature'] ?? '--'}°C',
        'status': _deriveStatus(pulse, ppm),
      };

      // EVALUATE ALERTS
      final tempStr = record['temperature']?.toString();
      final double? temp = tempStr != null ? double.tryParse(tempStr) : null;

      final newAlerts = _alertEngine.evaluate(
        patientId: patientId,
        hr: pulse,
        spo2: ppm,
        temp: temp,
      );

      if (newAlerts.isNotEmpty) {
        _activeAlerts = [..._activeAlerts, ...newAlerts];
        _repository.logAlertsToCloud(newAlerts, patientId);
      }

      notifyListeners();
    }
  }

  void dismissAlert(String alertId) {
    _activeAlerts.removeWhere((a) => a.id == alertId);
    notifyListeners();
  }

  String _deriveStatus(int pulse, int ppm) {
    if (pulse > 100 || pulse < 55 || ppm < 90) return 'critical';
    if (pulse > 90 || pulse < 60 || ppm < 95) return 'warning';
    return 'normal';
  }

  @override
  void dispose() {
    _reportsChannel?.unsubscribe();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _handleError(dynamic e) {
    return ErrorMapper.map(e);
  }
}
