import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:vitaguard_app/core/utils/uuid.dart';

class FacilityRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  SupabaseClient get _client => _supabase.client;
  String get _uid => _supabase.currentUid;

  Future<void> uploadMedicalTest({
    String? patientId,
    String? patientPhone,
    required String testType,
    required String filePath,
    String? notes,
  }) async {
    String? resolvedPatientId = patientId;

    if (resolvedPatientId == null && patientPhone != null && patientPhone.isNotEmpty) {
      final userSnapshot = await _client
          .from('profiles')
          .select('id')
          .eq('phone', patientPhone)
          .eq('role', 'patient')
          .limit(1);
      if (userSnapshot.isNotEmpty) {
        resolvedPatientId = userSnapshot.first['id'] as String?;
      }
    }

    final file = File(filePath);
    final size = await file.length();
    if (size > 10 * 1024 * 1024) {
      throw StateError('File too large. Maximum size is 10 MB.');
    }
    final contentType = _contentTypeForFile(file.path);
    if (contentType == 'application/octet-stream') {
      throw StateError('Invalid file type. Please upload a JPEG, PNG, or PDF.');
    }

    await _client.functions.invoke(
      'upload_lab_report',
      body: {
        'facility_id': _uid,
        'patient_id': resolvedPatientId,
        'test_type': testType,
        'notes': notes,
        'report_id': Uuid.v4(),
        'filename': _basename(file.path),
        'content_type': _contentTypeForFile(file.path),
        'data': base64Encode(await file.readAsBytes()),
      },
    );
  }

  Future<void> createOffer({
    required String title,
    required String description,
    File? image,
  }) async {
    if (image != null) {
      final size = await image.length();
      if (size > 10 * 1024 * 1024) {
        throw StateError('Image too large. Maximum size is 10 MB.');
      }
      final contentType = _contentTypeForFile(image.path);
      if (contentType == 'application/octet-stream') {
        throw StateError('Invalid file type. Please upload a JPEG, PNG, or PDF.');
      }

      await _client.functions.invoke(
        'upload_lab_offer',
        body: {
          'facility_id': _uid,
          'offer_id': Uuid.v4(),
          'title': title,
          'description': description,
          'filename': _basename(image.path),
          'content_type': _contentTypeForFile(image.path),
          'data': base64Encode(await image.readAsBytes()),
        },
      );
      return;
    }

    await _client.from('facility_offers').insert({
      'facility_id': _uid,
      'title': title,
      'description': description,
      'is_active': true,
    });
  }

  Future<List<dynamic>> getAppointments() async {
    final snapshot = await _client
        .from('facility_appointments')
        .select()
        .eq('facility_id', _uid)
        .order('scheduled_at', ascending: false);

    return snapshot;
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
