import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vitaguard_app/core/ai/xray_inference_service.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:vitaguard_app/core/utils/uuid.dart';
import 'package:vitaguard_app/patient/models/patient_models.dart';

class PatientRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  SupabaseClient get _client => _supabase.client;

  String get _uid => _supabase.currentUid;

  Future<List<Map<String, dynamic>>> getAvailableDoctors() async {
    final response = await _client
        .from('profiles')
        .select('id, name, email')
        .eq('role', 'doctor')
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> submitDailyReport(DailyReport report) async {
    final data = report.toMap();
    await _client.from('patient_daily_reports').insert({
      'patient_id': _uid,
      'report_date': (data['reportDate'] as DateTime?)?.toIso8601String(),
      'heart_rate': data['heartRate'],
      'oxygen_level': data['oxygenLevel'],
      'temperature': data['temperature'],
      'blood_pressure': data['bloodPressure'],
      'tasks_activities': data['tasksActivities'],
      'notes': data['notes'],
    });
  }

  Future<void> updateMedicalHistory(MedicalHistory history) async {
    final patientId = await ensureCurrentPatientRecord();
    await updateMedicalHistoryForPatient(history, patientId: patientId);
  }

  Future<void> updateMedicalHistoryForPatient(
    MedicalHistory history, {
    required String patientId,
  }) async {
    final data = history.toMap();
    await _client.from('patient_medical_history').upsert({
      'patient_id': patientId,
      'allergies': data['allergies'],
      'medications': data['medications'],
      'chronic_diseases': data['chronicDiseases'],
      'surgeries': data['surgeries'],
      'notes': data['notes'],
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<MedicalHistory> getMedicalHistory() async {
    final patientId = await ensureCurrentPatientRecord();
    return getMedicalHistoryForPatient(patientId: patientId);
  }

  Future<MedicalHistory> getMedicalHistoryForPatient({
    required String patientId,
  }) async {
    final data = await _client
        .from('patient_medical_history')
        .select()
        .eq('patient_id', patientId)
        .limit(1);

    if (data.isNotEmpty) {
      return MedicalHistory.fromMap(
        Map<String, dynamic>.from(data.first as Map),
      );
    }

    return MedicalHistory.empty();
  }

  Future<String> ensureCurrentPatientRecord() async {
    final patientId = _uid;

    final existingPatient = await _client
        .from('patients')
        .select('id')
        .eq('id', patientId)
        .limit(1);
    if (existingPatient.isNotEmpty) {
      return patientId;
    }

    final user = _supabase.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};

    final existingProfile = await _client
        .from('profiles')
        .select('id')
        .eq('id', patientId)
        .limit(1);
    if (existingProfile.isEmpty) {
      await _client.from('profiles').insert({
        'id': patientId,
        'role': 'patient',
        'name': metadata['name'],
        'email': user?.email,
        'phone': metadata['phone'],
      });
    }

    await _client.from('patients').upsert({
      'id': patientId,
      'gender': (metadata['gender'] as String?)?.trim().isNotEmpty == true
          ? metadata['gender']
          : 'male',
      'age': int.tryParse(metadata['age']?.toString() ?? '') ?? 20,
      'companion_code': metadata['companion_code'] as String?,
    });

    final repairedPatient = await _client
        .from('patients')
        .select('id')
        .eq('id', patientId)
        .limit(1);
    if (repairedPatient.isEmpty) {
      throw StateError(
        'Your patient profile is still being set up. Please sign out and sign back in, then try again.',
      );
    }

    return patientId;
  }

  Future<XRayResult> analyzeXRay(File imageFile, {String? patientId}) async {
    final uid = _supabase.currentUidOrNull;
    if (uid == null) {
      throw StateError('You must be logged in to perform a scan.');
    }

    // On-device TFLite inference — fast, reliable, no network dependency.
    // Background Supabase logging is handled inside the service itself.
    final logPatientId = patientId ?? await _currentPatientLogIdOrNull();
    final result = await XrayInferenceService.instance.analyze(
      imageFile,
      patientIdForLog: logPatientId,
    );
    return result;
  }

  Future<String?> _currentPatientLogIdOrNull() async {
    final rows = await _client
        .from('profiles')
        .select('role')
        .eq('id', _uid)
        .limit(1);

    if (rows.isEmpty) return null;
    return rows.first['role']?.toString() == 'patient' ? _uid : null;
  }

  Future<void> uploadMedicalDocument(File documentFile) async {
    final size = await documentFile.length();
    if (size > 10 * 1024 * 1024) {
      throw StateError('File too large. Maximum size is 10 MB.');
    }
    final contentType = _contentTypeForFile(documentFile.path);
    if (contentType == 'application/octet-stream') {
      throw StateError('Invalid file type. Please upload a JPEG, PNG, or PDF.');
    }

    await _client.functions.invoke(
      'upload_medical_record',
      body: {
        'patient_id': _uid,
        'document_id': Uuid.v4(),
        'filename': _basename(documentFile.path),
        'content_type': _contentTypeForFile(documentFile.path),
        'data': base64Encode(await documentFile.readAsBytes()),
      },
    );
  }

  Future<String> getCompanionCode() async {
    final data = await _client
        .from('patients')
        .select('companion_code')
        .eq('id', _uid)
        .limit(1);
    if (data.isNotEmpty) {
      final code = data.first['companion_code'];
      if (code is String && code.isNotEmpty) {
        return code;
      }
    }

    final newCode = await _generateUniqueCompanionCode();
    await _client
        .from('patients')
        .update({'companion_code': newCode})
        .eq('id', _uid);
    return newCode;
  }

  Future<String> regenerateCompanionCode() async {
    final newCode = await _generateUniqueCompanionCode();
    await _client
        .from('patients')
        .update({'companion_code': newCode})
        .eq('id', _uid);
    return newCode;
  }

  Future<String> _generateUniqueCompanionCode() async {
    try {
      final response = await _client.functions.invoke(
        'generate_companion_code',
      );
      final data = response.data;
      if (data is Map && data['code'] is String) {
        return data['code'] as String;
      }
    } catch (_) {
      // fall back to local generation if edge function unavailable
    }

    return _generateLocalCompanionCode();
  }

  Future<String> _generateLocalCompanionCode() async {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    for (var attempt = 0; attempt < 10; attempt++) {
      final code = List.generate(
        6,
        (_) => alphabet[Random.secure().nextInt(alphabet.length)],
      ).join();
      final existing = await _client
          .from('patients')
          .select('id')
          .eq('companion_code', code)
          .limit(1);
      if (existing.isEmpty) {
        return code;
      }
    }

    return List.generate(
      6,
      (_) => alphabet[Random.secure().nextInt(alphabet.length)],
    ).join();
  }

  String _basename(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  String _contentTypeForFile(String path) {
    final ext = path.toLowerCase();
    if (ext.endsWith('.png')) return 'image/png';
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) return 'image/jpeg';
    if (ext.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }
}
