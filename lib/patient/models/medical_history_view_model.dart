import 'package:flutter/material.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/patient/models/patient_models.dart';
import 'package:vitaguard_app/patient/data/patient_repository.dart';

enum MedicalHistoryAccessMode { patient, companion, draft }

class MedicalHistoryViewModel extends ChangeNotifier {
  MedicalHistoryViewModel._({
    required MedicalHistoryAccessMode mode,
    String? patientId,
    MedicalHistory? initialHistory,
  }) : _mode = mode,
       _patientId = patientId,
       _initialHistory = initialHistory;

  factory MedicalHistoryViewModel.forPatient() {
    return MedicalHistoryViewModel._(mode: MedicalHistoryAccessMode.patient);
  }

  factory MedicalHistoryViewModel.forCompanion({required String patientId}) {
    return MedicalHistoryViewModel._(
      mode: MedicalHistoryAccessMode.companion,
      patientId: patientId,
    );
  }

  factory MedicalHistoryViewModel.forDraft({MedicalHistory? initialHistory}) {
    return MedicalHistoryViewModel._(
      mode: MedicalHistoryAccessMode.draft,
      initialHistory: initialHistory,
    );
  }

  final MedicalHistoryAccessMode _mode;
  final String? _patientId;
  final MedicalHistory? _initialHistory;
  final PatientRepository _repository = PatientRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  MedicalHistory? _history;
  MedicalHistory? get history => _history;
  bool get isDraftMode => _mode == MedicalHistoryAccessMode.draft;
  bool get isReadOnly => _mode == MedicalHistoryAccessMode.companion;
  bool get isPatientMode => _mode == MedicalHistoryAccessMode.patient;
  bool get isCreateMode => (_history ?? MedicalHistory.empty()).isEmpty;

  Future<void> fetchHistory() async {
    if (_history != null) return; // Prevent refetching if already loaded

    if (isDraftMode) {
      _history = _initialHistory ?? MedicalHistory.empty();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (isReadOnly) {
        _history = await _repository.getMedicalHistoryForPatient(
          patientId: _patientId!,
        );
      } else {
        _history = await _repository.getMedicalHistory();
      }
    } catch (e) {
      _error = ErrorMapper.map(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveHistory(MedicalHistory newHistory) async {
    if (isReadOnly) {
      _error = 'Companions can only view medical history.';
      notifyListeners();
      return false;
    }

    if (isDraftMode) {
      _history = newHistory;
      _error = null;
      notifyListeners();
      return true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateMedicalHistory(newHistory);
      _history = newHistory;
      return true;
    } catch (e) {
      _error = ErrorMapper.map(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
