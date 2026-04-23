import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/patient/data/patient_repository.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';

class PatientProvider with ChangeNotifier {
  final PatientRepository _repository = PatientRepository();

  PatientRepository get repository => _repository;

  bool _isLoading = false;
  String? _error;
  XRayResult? _lastXRayResult;

  bool get isLoading => _isLoading;
  String? get error => _error;
  XRayResult? get lastXRayResult => _lastXRayResult;
  String? _companionCode;
  String? get companionCode => _companionCode;

  MedicalHistory? _medicalHistory;
  MedicalHistory? get medicalHistory => _medicalHistory;

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
      _medicalHistory = history;
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

  Future<void> fetchCompanionCode() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _companionCode = await _repository.getCompanionCode();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = _handleError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMedicalHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medicalHistory = await _repository.getMedicalHistory();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = _handleError(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  String _handleError(dynamic e) {
    return ErrorMapper.map(e);
  }

  Future<bool> regenerateCompanionCode() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _companionCode = await _repository.regenerateCompanionCode();
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
}
