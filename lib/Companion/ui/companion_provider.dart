import 'package:flutter/material.dart';
import '../data/companion_repository.dart';

class CompanionProvider with ChangeNotifier {
  final CompanionRepository _repository = CompanionRepository();

  bool _isLoading = false;
  String? _error;
  dynamic _patientStatus;

  bool get isLoading => _isLoading;
  String? get error => _error;
  dynamic get patientStatus => _patientStatus;

  Future<bool> linkPatient(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.linkPatient(code);
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

  Future<void> fetchPatientStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _patientStatus = await _repository.getPatientStatus();
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
