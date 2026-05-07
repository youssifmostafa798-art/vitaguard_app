import 'dart:io';
import 'package:flutter/foundation.dart';
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

    // Upload directly to Supabase Storage (avoids Edge Function 2 MB body
    // limit that caused 400 Bad Request for even moderate-sized files).
    final reportId = Uuid.v4();
    final ext = _fileExtension(file.path);
    final storagePath = '$_uid/$reportId$ext';

    debugPrint('[FACILITY] Uploading $storagePath ($size bytes)');

    await _client.storage.from('lab-reports').upload(
      storagePath,
      file,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: true,
      ),
    );

    final insertError = await _client.from('facility_tests').insert({
      'id': reportId,
      'facility_id': _uid,
      'patient_id': resolvedPatientId,
      'test_type': testType,
      'file_path': storagePath,
      'notes': notes,
    }).then((_) => null, onError: (e) => e);

    if (insertError != null) {
      // Best-effort cleanup — don't let a stale file linger.
      try {
        await _client.storage.from('lab-reports').remove([storagePath]);
      } catch (_) {}
      throw insertError;
    }
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

    final offerId = Uuid.v4();
    String? imagePath;

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

      final ext = _fileExtension(image.path);
      final storagePath = '$_uid/$offerId$ext';

      debugPrint('[FACILITY] Uploading offer image $storagePath');

      await _client.storage.from('lab-offers').upload(
        storagePath,
        image,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      imagePath = storagePath;
    }

    await _client.from('facility_offers').insert({
      'id': offerId,
      'facility_id': _uid,
      'title': cleanTitle,
      'description': cleanDescription,
      'image_path': imagePath,
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

  String _fileExtension(String path) {
    final parts = path.toLowerCase().split('.');
    if (parts.length < 2) return '';
    return '.${parts.last}';
  }

  String _contentTypeForFile(String path) {
    final ext = path.toLowerCase();
    if (ext.endsWith('.png')) return 'image/png';
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) return 'image/jpeg';
    if (ext.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }
}
