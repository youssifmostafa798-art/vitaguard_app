import 'package:flutter/material.dart';
import '../../core/network/dio_error_mapper.dart';
import '../data/doctor_repository.dart';

class DoctorProvider with ChangeNotifier {
  final DoctorRepository _repository = DoctorRepository();

  bool _isLoading = false;
  String? _error;
  List<dynamic> _assignedPatients = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get assignedPatients => _assignedPatients;

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

  String _handleError(dynamic e) {
    return DioErrorMapper.map(e);
  }
}
