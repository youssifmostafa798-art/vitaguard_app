import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vitaguard_app/core/supabase/supabase_service.dart';

class DoctorRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  SupabaseClient get _client => _supabase.client;
  String get _uid => _supabase.currentUid;

  Future<List<Map<String, dynamic>>> getAssignedPatients() async {
    final results = <Map<String, dynamic>>[];

    final patients = await _client
        .from('patients')
        .select('id, gender, age, profiles(name)')
        .eq('assigned_doctor_id', _uid);

    for (final entry in patients) {
      final data = Map<String, dynamic>.from(entry as Map);
      final profile = data['profiles'] as Map?;
      results.add({
        'patient_id': data['id'],
        'name': profile?['name'] ?? 'Unknown',
        'age': data['age'],
        'gender': data['gender'],
      });
    }

    return results;
  }

  Future<void> sendFeedback({
    required String patientId,
    required String feedbackText,
    String? xrayResultId,
  }) async {
    await _client.from('medical_feedback').insert({
      'doctor_id': _uid,
      'patient_id': patientId,
      'xray_result_id': xrayResultId,
      'feedback_text': feedbackText,
    });
  }

  Future<Map<String, dynamic>> getVerificationStatus() async {
    final data = await _client.from('doctors').select().eq('id', _uid).limit(1);
    if (data.isNotEmpty) {
      final row = Map<String, dynamic>.from(data.first as Map);
      return {
        'verificationStatus': row['verification_status'] ?? 'pending',
        'idCardImageUrl': row['id_card_path'],
        'reviewedAt': row['reviewed_at'],
      };
    }

    return {
      'verificationStatus': 'pending',
      'idCardImageUrl': null,
      'reviewedAt': null,
    };
  }
}
