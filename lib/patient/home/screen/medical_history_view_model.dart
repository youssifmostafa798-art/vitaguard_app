import 'package:flutter/material.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';

class MedicalHistoryViewModel extends ChangeNotifier {
  final String? overridePatientId;

  MedicalHistoryViewModel({this.overridePatientId});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  MedicalHistory? _history;
  MedicalHistory? get history => _history;

  Future<void> fetchHistory() async {
    if (_history != null) return; // Prevent refetching if already loaded
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final client = SupabaseService.instance.client;
      final targetUid = overridePatientId ?? SupabaseService.instance.currentUid;
      
      final data = await client
          .from('patient_medical_history')
          .select()
          .eq('patient_id', targetUid)
          .limit(1);

      if (data.isNotEmpty) {
        _history = MedicalHistory.fromMap(Map<String, dynamic>.from(data.first as Map));
      } else {
        _history = MedicalHistory(chronicDiseases: '', medications: '', allergies: '', surgeries: '', notes: '');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveHistory(MedicalHistory newHistory) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final client = SupabaseService.instance.client;
      final targetUid = overridePatientId ?? SupabaseService.instance.currentUid;
      
      await client.from('patient_medical_history').upsert({
        'patient_id': targetUid,
        'allergies': newHistory.allergies,
        'medications': newHistory.medications,
        'chronic_diseases': newHistory.chronicDiseases,
        'surgeries': newHistory.surgeries,
        'notes': newHistory.notes,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _history = newHistory;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
