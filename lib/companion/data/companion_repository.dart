import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vitaguard_app/core/supabase/supabase_service.dart';

class CompanionRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  SupabaseClient get _client => _supabase.client;
  String get _uid => _supabase.currentUid;

  Future<void> linkPatient(String code) async {
    final success = await _client.rpc(
      'link_companion_to_patient',
      params: {'p_code': code},
    );

    if (success != true) {
      throw StateError('Invalid companion code.');
    }
  }

  Future<dynamic> getPatientStatus() async {
    final companionData = await _client
        .from('companions')
        .select()
        .eq('id', _uid)
        .limit(1);
    if (companionData.isEmpty) {
      throw StateError('No linked patient found.');
    }

    final linkedPatientId = companionData.first['linked_patient_id'];
    if (linkedPatientId == null) {
      throw StateError('No linked patient found.');
    }

    final patientData = await _client
        .from('patients')
        .select('id, gender, age, profiles(name)')
        .eq('id', linkedPatientId)
        .limit(1);

    if (patientData.isNotEmpty) {
      final row = Map<String, dynamic>.from(patientData.first as Map);
      final profile = row['profiles'] as Map?;
      return {
        'patient_id': row['id'],
        'name': profile?['name'] ?? 'Unknown',
        'age': row['age'],
        'gender': row['gender'],
      };
    }

    throw StateError('No linked patient found.');
  }

  /// Returns the companion code of the patient linked to this companion account.
  Future<String?> getLinkedPatientCode() async {
    final companionData = await _client
        .from('companions')
        .select('linked_patient_id')
        .eq('id', _uid)
        .limit(1);

    if (companionData.isEmpty) return null;

    final linkedPatientId = companionData.first['linked_patient_id'];
    if (linkedPatientId == null) return null;

    final patientData = await _client
        .from('patients')
        .select('companion_code')
        .eq('id', linkedPatientId as String)
        .limit(1);

    if (patientData.isEmpty) return null;
    return patientData.first['companion_code'] as String?;
  }
}
