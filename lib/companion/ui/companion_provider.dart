import 'package:flutter/material.dart';
import 'package:vitaguard_app/companion/data/companion_models.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/companion/data/companion_repository.dart';

class CompanionProvider with ChangeNotifier {
  final CompanionRepository _repository = CompanionRepository();

  bool _isLoading = false;
  String? _error;
  LinkedPatientStatus? _patientStatus;
  String? _companionCode;

  bool get isLoading => _isLoading;
  String? get error => _error;
  LinkedPatientStatus? get patientStatus => _patientStatus;
  String? get companionCode => _companionCode;

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

  /// Fetches the companion code of the linked patient.
  Future<void> fetchLinkedPatientCode() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _companionCode = await _repository.getLinkedPatientCode();
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

