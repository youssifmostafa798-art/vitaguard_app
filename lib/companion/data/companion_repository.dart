import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vitaguard_app/core/supabase/supabase_service.dart';

class CompanionRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  SupabaseClient get _client => _supabase.client;
  String get _uid => _supabase.currentUid;

  Future<void> linkPatient(String code) async {
    final snapshot = await _client
        .from('patients')
        .select('id')
        .eq('companion_code', code)
        .limit(1);

    final patientId = snapshot.isNotEmpty
        ? snapshot.first['id'] as String?
        : null;
    if (patientId == null) {
      throw StateError('Invalid companion code.');
    }

    await _client.from('companions').upsert({
      'id': _uid,
      'linked_patient_id': patientId,
    });
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
}
