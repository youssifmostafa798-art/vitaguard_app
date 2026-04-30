import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vitaguard_app/core/utils/uuid.dart';

part 'facility_repository.g.dart';

@riverpod
FacilityRepository facilityRepository(Ref ref) {
  return FacilityRepository(supabase: ref.watch(supabaseServiceProvider));
}

class FacilityRepository {
  FacilityRepository({SupabaseService? supabase})
    : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;

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

    if (resolvedPatientId == null &&
        patientPhone != null &&
        patientPhone.isNotEmpty) {
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

    await _supabase.invokeFunction(
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
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();

    if (cleanTitle.isEmpty) {
      throw StateError('Offer title is required.');
    }
    if (cleanDescription.isEmpty) {
      throw StateError('Offer description is required.');
    }

    if (image != null) {
      final size = await image.length();
      if (size > 10 * 1024 * 1024) {
        throw StateError('Image too large. Maximum size is 10 MB.');
      }
      final contentType = _contentTypeForFile(image.path);
      if (contentType == 'application/octet-stream') {
        throw StateError(
          'Invalid cover image type. Please upload a JPEG or PNG image.',
        );
      }

      await _supabase.invokeFunction(
        'upload_lab_offer',
        body: {
          'facility_id': _uid,
          'offer_id': Uuid.v4(),
          'title': cleanTitle,
          'description': cleanDescription,
          'filename': _basename(image.path),
          'content_type': contentType,
          'data': base64Encode(await image.readAsBytes()),
        },
      );
      return;
    }

    await _client.from('facility_offers').insert({
      'facility_id': _uid,
      'title': cleanTitle,
      'description': cleanDescription,
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
    return 'application/octet-stream';
  }
}