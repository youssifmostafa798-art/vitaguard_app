import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vitaguard_app/auth/data/auth_models.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';

class AuthRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  SupabaseClient get _client => _supabase.client;

  Future<void> login(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> registerPatient({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    String? gender,
    String? age,
  }) async {
    final response = await _client.auth.signUp(email: email, password: password);
    final user = response.user;
    if (user == null) {
      throw StateError('Account created. Please verify your email to continue.');
    }

    final uid = user.id;
    final companionCode = await _resolveCompanionCode();

    await _client.from('profiles').insert({
      'id': uid,
      'role': UserRole.patient.value,
      'name': fullName,
      'email': email,
      'phone': phone,
      'is_active': true,
      'is_verified': false,
    });

    await _client.from('patients').insert({
      'id': uid,
      'gender': (gender == null || gender.trim().isEmpty)
          ? 'male'
          : gender.trim().toLowerCase(),
      'age': int.tryParse(age ?? '20') ?? 20,
      'companion_code': companionCode,
      'assigned_doctor_id': null,
    });
  }

  Future<void> registerDoctor({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String professionalId,
    required File? idCardImage,
    String? gender,
    String? age,
  }) async {
    final response = await _client.auth.signUp(email: email, password: password);
    final user = response.user;
    if (user == null) {
      throw StateError('Account created. Please verify your email to continue.');
    }

    final uid = user.id;

    await _client.from('profiles').insert({
      'id': uid,
      'role': UserRole.doctor.value,
      'name': fullName,
      'email': email,
      'phone': phone,
      'is_active': true,
      'is_verified': false,
    });

    await _client.from('doctors').insert({
      'id': uid,
      'gender': (gender == null || gender.trim().isEmpty)
          ? 'male'
          : gender.trim().toLowerCase(),
      'age': int.tryParse(age ?? '30') ?? 30,
      'professional_id': professionalId,
      'verification_status': 'pending',
      'id_card_path': null,
      'reviewed_by': null,
      'reviewed_at': null,
    });

    if (idCardImage != null) {
      await _client.functions.invoke(
        'upload_doctor_verification',
        body: {
          'doctor_id': uid,
          'filename': _basename(idCardImage.path),
          'content_type': _contentTypeForExtension(_fileExtension(idCardImage)) ??
              'application/octet-stream',
          'data': base64Encode(await idCardImage.readAsBytes()),
        },
      );
    }
  }

  Future<void> registerCompanion({
    required String name,
    required String email,
    required String password,
    required String companionCode,
  }) async {
    final patientSnapshot = await _client
        .from('patients')
        .select('id')
        .eq('companion_code', companionCode)
        .limit(1);

    final patientId = (patientSnapshot is List && patientSnapshot.isNotEmpty)
        ? patientSnapshot.first['id'] as String?
        : null;
    if (patientId == null) {
      throw StateError('Invalid companion code.');
    }

    final response = await _client.auth.signUp(email: email, password: password);
    final user = response.user;
    if (user == null) {
      throw StateError('Account created. Please verify your email to continue.');
    }

    final uid = user.id;

    await _client.from('profiles').insert({
      'id': uid,
      'role': UserRole.companion.value,
      'name': name,
      'email': email,
      'phone': null,
      'is_active': true,
      'is_verified': true,
    });

    await _client.from('companions').insert({
      'id': uid,
      'linked_patient_id': patientId,
    });
  }

  Future<void> registerFacility({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String facilityType,
    required File? recordImage,
  }) async {
    final response = await _client.auth.signUp(email: email, password: password);
    final user = response.user;
    if (user == null) {
      throw StateError('Account created. Please verify your email to continue.');
    }

    final uid = user.id;

    String? recordPath;
    if (recordImage != null) {
      final ext = _fileExtension(recordImage);
      final path = '$uid/record$ext';
      await _client.storage.from('facility-records').upload(
            path,
            recordImage,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _contentTypeForExtension(ext),
            ),
          );
      recordPath = path;
    }

    await _client.from('profiles').insert({
      'id': uid,
      'role': UserRole.facility.value,
      'name': name,
      'email': email,
      'phone': phone,
      'is_active': true,
      'is_verified': false,
    });

    await _client.from('facilities').insert({
      'id': uid,
      'address': address,
      'facility_type': facilityType,
      'record_path': recordPath,
      'verification_status': 'pending',
    });
  }

  Future<Map<String, dynamic>> getMe() async {
    final uid = _supabase.currentUid;
    final profileSnapshot =
        await _client.from('profiles').select().eq('id', uid).limit(1);
    final profile = (profileSnapshot is List && profileSnapshot.isNotEmpty)
        ? Map<String, dynamic>.from(profileSnapshot.first as Map)
        : <String, dynamic>{};
    profile['uid'] = uid;

    final role = profile['role'];
    if (role == UserRole.patient.value) {
      final patientSnapshot =
          await _client.from('patients').select().eq('id', uid).limit(1);
      if (patientSnapshot is List && patientSnapshot.isNotEmpty) {
        profile.addAll(Map<String, dynamic>.from(patientSnapshot.first as Map));
      }
    } else if (role == UserRole.doctor.value) {
      final doctorSnapshot =
          await _client.from('doctors').select().eq('id', uid).limit(1);
      if (doctorSnapshot is List && doctorSnapshot.isNotEmpty) {
        profile.addAll(Map<String, dynamic>.from(doctorSnapshot.first as Map));
      }
    } else if (role == UserRole.companion.value) {
      final companionSnapshot =
          await _client.from('companions').select().eq('id', uid).limit(1);
      if (companionSnapshot is List && companionSnapshot.isNotEmpty) {
        profile.addAll(Map<String, dynamic>.from(companionSnapshot.first as Map));
      }
    } else if (role == UserRole.facility.value) {
      final facilitySnapshot =
          await _client.from('facilities').select().eq('id', uid).limit(1);
      if (facilitySnapshot is List && facilitySnapshot.isNotEmpty) {
        profile.addAll(Map<String, dynamic>.from(facilitySnapshot.first as Map));
      }
    }

    return profile;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<bool> isAuthenticated() async {
    return _client.auth.currentUser != null;
  }

  Future<String> _resolveCompanionCode() async {
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
    final random = Random.secure();

    for (var attempt = 0; attempt < 8; attempt++) {
      final code = List.generate(6, (_) => alphabet[random.nextInt(alphabet.length)])
          .join();
      try {
        final existing = await _client
            .from('patients')
            .select('id')
            .eq('companion_code', code)
            .limit(1);
        if (existing is List && existing.isEmpty) {
          return code;
        }
      } catch (_) {
        // ignore and retry
      }
    }

    return List.generate(6, (_) => alphabet[random.nextInt(alphabet.length)])
        .join();
  }

  String _fileExtension(File file) {
    final parts = file.path.split('.');
    if (parts.length < 2) return '';
    return '.${parts.last.toLowerCase()}';
  }

  String _basename(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  String? _contentTypeForExtension(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.pdf':
        return 'application/pdf';
      default:
        return null;
    }
  }
}
