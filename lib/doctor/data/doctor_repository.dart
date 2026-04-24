import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/doctor/data/vital_alert_model.dart';

import 'package:vitaguard_app/core/supabase/supabase_service.dart';

class DoctorRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  SupabaseClient get _client => _supabase.client;
  String get _uid => _supabase.currentUid;

  // ---------------------------------------------------------------------------
  // Patients
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Medical Feedback
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Verification
  // ---------------------------------------------------------------------------

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

  /// Returns a short-lived signed URL (1 hour) for the doctor's ID-card image,
  /// or null if no image path is stored yet.
  Future<String?> getSignedIdCardUrl() async {
    final status = await getVerificationStatus();
    final path = status['idCardImagePath'] as String?;
    if (path == null || path.isEmpty) return null;

    final signedUrl = await _client.storage
        .from('doctor-verifications')
        .createSignedUrl(path, 3600);
    return signedUrl;
  }

  // ---------------------------------------------------------------------------
  // Medical Reports  (Problem 2)
  // ---------------------------------------------------------------------------

  /// Uploads an optional image to Storage then inserts a row in
  /// [doctor_medical_reports]. The [patientPhone] and [patientName] fields are
  /// free-text identifiers entered by the doctor.
  Future<void> uploadMedicalReport({
    required String patientPhone,
    required String patientName,
    required String description,
    File? imageFile,
  }) async {
    String? imagePath;

    if (imageFile != null) {
      final ext = _fileExtension(imageFile.path);
      final fileName =
          '$_uid/${DateTime.now().millisecondsSinceEpoch}$ext';

      await _client.storage
          .from('medical records')
          .upload(
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

  // ---------------------------------------------------------------------------
  // Daily Reports  (Problem 4)
  // ---------------------------------------------------------------------------

  /// Returns the most recent daily report for each patient assigned to this doctor.
  /// Columns are mapped to match [DailyReportModel] field names used in the UI.
  Future<List<Map<String, dynamic>>> getAllAssignedPatientsDailyReports() async {
    // Step 1 — fetch the doctor's assigned patients (with name from profiles).
    final patients = await _client
        .from('patients')
        .select('id, gender, age, profiles(name)')
        .eq('assigned_doctor_id', _uid);

    if (patients.isEmpty) return [];

    final patientIds =
        patients.map((p) => (p as Map)['id'] as String).toList();

    // Step 2 — fetch all reports for those patients, newest-first.
    final reports = await _client
        .from('patient_daily_reports')
        .select()
        .inFilter('patient_id', patientIds)
        .order('report_date', ascending: false);

    // Step 3 — take only the most-recent report per patient.
    final results = <Map<String, dynamic>>[];
    final seenPatients = <String>{};

    for (final entry in reports) {
      final data = Map<String, dynamic>.from(entry as Map);
      final patientId = data['patient_id'] as String? ?? '';
      if (seenPatients.contains(patientId)) continue;
      seenPatients.add(patientId);

      // Find matching patient info.
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
        'temperature': '${data['temperature'] ?? '--'}°C',
        'motionStatus': data['tasks_activities']?.toString() ?? 'N/A',
        'notes': data['notes']?.toString() ?? '',
        // Derive status from vitals so the UI badges remain meaningful.
        'status': _deriveStatus(pulse, ppm),
      });
    }

    // Include patients who have no reports yet.
    for (final p in patients) {
      final pid = (p as Map)['id'] as String;
      if (!seenPatients.contains(pid)) {
        final profile = (p['profiles'] as Map?) ?? {};
        results.add({
          'id': pid,
          'patientName': profile['name']?.toString() ?? 'Unknown',
          'date': '—',
          'pulse': 0,
          'ppm': 0,
          'temperature': '—',
          'motionStatus': 'N/A',
          'notes': 'No reports yet',
          'status': 'normal',
        });
      }
    }

    return results;
  }

  /// Sets up a real-time subscription for all patients assigned to the current doctor.
  /// Fires [onUpdate] whenever a new row is inserted in 'patient_live_vitals'
  /// for any of the assigned patients.
  RealtimeChannel subscribeToAssignedPatientsVitals({
    required List<String> patientIds,
    required void Function(Map<String, dynamic> newRecord) onUpdate,
  }) {
    final channelId = 'doctor_vitals_mon_${_uid.substring(0, 8)}';

    return _client
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
  }


  /// Returns all daily reports (newest-first) for a single patient.
  Future<List<Map<String, dynamic>>> getPatientDailyReports(
    String patientId,
  ) async {
    final reports = await _client
        .from('patient_daily_reports')
        .select()
        .eq('patient_id', patientId)
        .order('report_date', ascending: false);

    return reports
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Alert Logging (Medical Audit Trail)
  // ---------------------------------------------------------------------------

  /// Logs alerts to the 'medical_alerts_log' table in Supabase for audit purposes.
  Future<void> logAlertsToCloud(List<VitalAlert> alerts, String patientId) async {
    if (alerts.isEmpty) return;

    final logs = alerts.map((alert) => {
      'patient_id': patientId,
      'doctor_id': _uid,
      'metric_type': alert.metrics.join(','),
      'severity': alert.severity.name,
      'alert_message': alert.message,
      'raw_values': alert.rawValues,
      'triggered_at': alert.timestamp.toIso8601String(),
    }).toList();

    await _client.from('medical_alerts_log').insert(logs);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
        'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  /// Derives a status string from heart-rate and oxygen-level readings.
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
