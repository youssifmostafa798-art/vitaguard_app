import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';

class DoctorRepository {
  DoctorRepository({SupabaseService? supabase})
    : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;

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
        'idCardImagePath': row['id_card_path'],
        'reviewedAt': row['reviewed_at'],
      };
    }

    return {
      'verificationStatus': 'pending',
      'idCardImagePath': null,
      'reviewedAt': null,
    };
  }

  Future<String?> getSignedIdCardUrl() async {
    final status = await getVerificationStatus();
    final path = status['idCardImagePath'] as String?;
    if (path == null || path.isEmpty) return null;

    final signedUrl = await _client.storage
        .from('doctor-verifications')
        .createSignedUrl(path, 3600);
    return signedUrl;
  }

  Future<void> uploadMedicalReport({
    required String patientPhone,
    required String patientName,
    required String description,
    File? imageFile,
  }) async {
    String? imagePath;

    if (imageFile != null) {
      final ext = _fileExtension(imageFile.path);
      final fileName = '$_uid/${DateTime.now().millisecondsSinceEpoch}$ext';

      await _client.storage.from('medical records').upload(
            fileName,
            imageFile,
            fileOptions: FileOptions(
              upsert: false,
              contentType: _contentType(ext),
            ),
          );

      imagePath = fileName;
    }

    await _client.from('doctor_medical_reports').insert({
      'doctor_id': _uid,
      'patient_phone': patientPhone.trim().isEmpty ? null : patientPhone.trim(),
      'patient_name': patientName.trim().isEmpty ? null : patientName.trim(),
      'description': description.trim().isEmpty ? null : description.trim(),
      'image_path': imagePath,
    });
  }

  Future<List<Map<String, dynamic>>> getAllAssignedPatientsDailyReports() async {
    final patients = await _client
        .from('patients')
        .select('id, gender, age, profiles(name)')
        .eq('assigned_doctor_id', _uid);

    if (patients.isEmpty) return [];

    final patientIds = patients.map((p) => (p as Map)['id'] as String).toList();

    final reports = await _client
        .from('patient_daily_reports')
        .select()
        .inFilter('patient_id', patientIds)
        .order('report_date', ascending: false);

    final results = <Map<String, dynamic>>[];
    final seenPatients = <String>{};

    for (final entry in reports) {
      final data = Map<String, dynamic>.from(entry as Map);
      final patientId = data['patient_id'] as String? ?? '';
      if (seenPatients.contains(patientId)) continue;
      seenPatients.add(patientId);

      final patientRow = patients.firstWhere(
        (p) => (p as Map)['id'] == patientId,
        orElse: () => <String, dynamic>{},
      );
      final patientMap = Map<String, dynamic>.from(patientRow as Map);
      final profile = (patientMap['profiles'] as Map?) ?? {};

      final pulse = (data['heart_rate'] as num?)?.toInt() ?? 0;
      final ppm = (data['oxygen_level'] as num?)?.toInt() ?? 0;

      results.add({
        'id': patientId,
        'patientName': profile['name']?.toString() ?? 'Unknown',
        'date': _formatDate(data['report_date']?.toString() ?? ''),
        'pulse': pulse,
        'ppm': ppm,
        'temperature': '${data['temperature'] ?? '--'}',
        'motionStatus': data['tasks_activities']?.toString() ?? 'N/A',
        'notes': data['notes']?.toString() ?? '',
        'status': _deriveStatus(pulse, ppm),
      });
    }

    for (final p in patients) {
      final pid = (p as Map)['id'] as String;
      if (!seenPatients.contains(pid)) {
        final profile = (p['profiles'] as Map?) ?? {};
        results.add({
          'id': pid,
          'patientName': profile['name']?.toString() ?? 'Unknown',
          'date': '--',
          'pulse': 0,
          'ppm': 0,
          'temperature': '--',
          'motionStatus': 'N/A',
          'notes': 'No reports yet',
          'status': 'normal',
        });
      }
    }

    return results;
  }

  SupabaseRealtimeSubscription subscribeToAssignedPatientsVitals({
    required List<String> patientIds,
    required void Function(Map<String, dynamic> newRecord) onUpdate,
  }) {
    final channelId = 'doctor_vitals_mon_${_uid.substring(0, 8)}';

    final channel = _supabase
        .channel(channelId)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'patient_live_vitals',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.inFilter,
            column: 'patient_id',
            value: patientIds,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
    return SupabaseRealtimeSubscription(channel);
  }

  Future<List<Map<String, dynamic>>> getPatientDailyReports(
    String patientId,
  ) async {
    final reports = await _client
        .from('patient_daily_reports')
        .select()
        .eq('patient_id', patientId)
        .order('report_date', ascending: false);

    return reports
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  String _deriveStatus(int pulse, int ppm) {
    if (pulse > 100 || pulse < 55 || ppm < 90) return 'critical';
    if (pulse > 90 || pulse < 60 || ppm < 95) return 'warning';
    return 'normal';
  }

  String _fileExtension(String path) {
    final parts = path.toLowerCase().split('.');
    if (parts.length < 2) return '';
    return '.${parts.last}';
  }

  String _contentType(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
