import 'package:flutter/material.dart';
import '../data/facility_repository.dart';

class FacilityProvider with ChangeNotifier {
  final FacilityRepository _repository = FacilityRepository();

  bool _isLoading = false;
  String? _error;
  List<dynamic> _appointments = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get appointments => _appointments;

  Future<bool> uploadMedicalTest({
    required String patientId,
    required String testType,
    required String filePath,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.uploadMedicalTest(
        patientId: patientId,
        testType: testType,
        filePath: filePath,
        notes: notes,
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

  Future<void> fetchAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _repository.getAppointments();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = _handleError(e);
      notifyListeners();
    }
  }

  String _handleError(dynamic e) {
    if (e is Exception) {
      return e.toString().replaceAll('Exception: ', '');
    }
    return 'An unexpected error occurred';
  }
}
