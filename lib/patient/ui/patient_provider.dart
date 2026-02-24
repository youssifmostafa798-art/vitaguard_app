import 'dart:io';
import 'package:flutter/material.dart';
import '../data/patient_repository.dart';
import '../data/patient_models.dart';

class PatientProvider with ChangeNotifier {
  final PatientRepository _repository = PatientRepository();

  PatientRepository get repository => _repository;

  bool _isLoading = false;
  String? _error;
  XRayResult? _lastXRayResult;

  bool get isLoading => _isLoading;
  String? get error => _error;
  XRayResult? get lastXRayResult => _lastXRayResult;

  Future<bool> submitDailyReport(DailyReport report) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.submitDailyReport(report);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _handleError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMedicalHistory(MedicalHistory history) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateMedicalHistory(history);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _handleError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> analyzeXRay(File image) async {
    _isLoading = true;
    _error = null;
    _lastXRayResult = null;
    notifyListeners();

    try {
      _lastXRayResult = await _repository.analyzeXRay(image);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _handleError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _handleError(dynamic e) {
    if (e is Exception) {
      return e.toString().replaceAll('Exception: ', '');
    }
    return 'An unexpected error occurred';
  }
}
