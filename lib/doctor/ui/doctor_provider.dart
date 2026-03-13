import 'package:flutter/material.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/doctor/data/doctor_repository.dart';

class DoctorProvider with ChangeNotifier {
  final DoctorRepository _repository = DoctorRepository();

  bool _isLoading = false;
  String? _error;
  List<dynamic> _assignedPatients = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get assignedPatients => _assignedPatients;
  String _verificationStatus = 'pending';
  String get verificationStatus => _verificationStatus;

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

  String _handleError(dynamic e) {
    return ErrorMapper.map(e);
  }
}
