import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/doctor/data/doctor_repository.dart';

class DoctorProvider with ChangeNotifier {
  final DoctorRepository _repository = DoctorRepository();

  bool _isLoading = false;
  String? _error;
  List<dynamic> _assignedPatients = [];
  String _verificationStatus = 'pending';
  List<Map<String, dynamic>> _dailyReports = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get assignedPatients => _assignedPatients;
  String get verificationStatus => _verificationStatus;
  List<Map<String, dynamic>> get dailyReports => _dailyReports;

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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _handleError(dynamic e) {
    return ErrorMapper.map(e);
  }
}
