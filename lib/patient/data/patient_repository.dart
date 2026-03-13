import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vitaguard_app/core/ai/xray_inference_service.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:vitaguard_app/core/utils/uuid.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';

class PatientRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  SupabaseClient get _client => _supabase.client;

  String get _uid => _supabase.currentUid;

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
    final data = history.toMap();
    await _client.from('patient_medical_history').upsert({
      'patient_id': _uid,
      'allergies': data['allergies'],
      'medications': data['medications'],
      'chronic_diseases': data['chronicDiseases'],
      'surgeries': data['surgeries'],
      'notes': data['notes'],
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<MedicalHistory> getMedicalHistory() async {
    final data = await _client
        .from('patient_medical_history')
        .select()
        .eq('patient_id', _uid)
        .limit(1);

    if (data.isNotEmpty) {
      return MedicalHistory.fromMap(
        Map<String, dynamic>.from(data.first as Map),
      );
    }

    return MedicalHistory(
      chronicDiseases: '',
      medications: '',
      allergies: '',
      surgeries: '',
      notes: '',
    );
  }

  Future<XRayResult> analyzeXRay(File imageFile) async {
    final result = await XrayInferenceService.instance.analyze(imageFile);

    if (!result.isValid) {
      await _client.from('patient_xray_results').insert({
        'patient_id': _uid,
        'is_valid': false,
        'prediction': result.prediction,
        'confidence': result.confidence,
        'report_text': result.reportText,
        'image_path': null,
      });

      return result;
    }

    final uploadResponse = await _client.functions.invoke(
      'upload_xray_result',
      body: {
        'patient_id': _uid,
        'filename': _basename(imageFile.path),
        'content_type': _contentTypeForFile(imageFile.path),
        'data': base64Encode(await imageFile.readAsBytes()),
        'report_text': result.reportText,
        'prediction': result.prediction,
        'confidence': result.confidence,
      },
    );

    final data = uploadResponse.data;
    final imagePath =
        (data is Map<String, dynamic>) ? data['image_path'] as String? : null;

    return XRayResult(
      isValid: result.isValid,
      prediction: result.prediction,
      confidence: result.confidence,
      reportText: result.reportText,
      imagePath: imagePath,
    );
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
    final data =
        await _client.from('patients').select('companion_code').eq('id', _uid).limit(1);
    if (data.isNotEmpty) {
      final code = data.first['companion_code'];
      if (code is String && code.isNotEmpty) {
        return code;
      }
    }

    final newCode = await _generateUniqueCompanionCode();
    await _client.from('patients').update({
      'companion_code': newCode,
    }).eq('id', _uid);
    return newCode;
  }

  Future<String> regenerateCompanionCode() async {
    final newCode = await _generateUniqueCompanionCode();
    await _client.from('patients').update({
      'companion_code': newCode,
    }).eq('id', _uid);
    return newCode;
  }

  Future<String> _generateUniqueCompanionCode() async {
    try {
      final response = await _client.functions.invoke('generate_companion_code');
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
      final code = List.generate(6, (_) => alphabet[Random.secure().nextInt(alphabet.length)])
          .join();
      final existing = await _client
          .from('patients')
          .select('id')
          .eq('companion_code', code)
          .limit(1);
      if (existing.isEmpty) {
        return code;
      }
    }

    return List.generate(6, (_) => alphabet[Random.secure().nextInt(alphabet.length)])
        .join();
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
