import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:vitaguard_app/auth/data/auth_models.dart';
import 'package:vitaguard_app/core/firebase/firebase_service.dart';

class AuthRepository {
  final FirebaseService _firebase = FirebaseService.instance;

  FirebaseAuth get _auth => _firebase.auth;
  FirebaseFirestore get _db => _firebase.firestore;
  FirebaseStorage get _storage => _firebase.storage;

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> registerPatient({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    String? gender,
    String? age,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    final companionCode = await _generateUniqueCompanionCode();

    await _db.collection('users').doc(uid).set({
      'role': UserRole.patient.value,
      'name': fullName,
      'email': email,
      'phone': phone,
      'isActive': true,
      'isVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('patients').doc(uid).set({
      'gender': (gender == null || gender.trim().isEmpty)
          ? 'male'
          : gender.trim().toLowerCase(),
      'age': int.tryParse(age ?? '20') ?? 20,
      'companionCode': companionCode,
      'assignedDoctorId': null,
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
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    String? idCardPath;
    if (idCardImage != null) {
      final ext = _fileExtension(idCardImage);
      final ref = _storage.ref('doctor_verifications/$uid/id_card$ext');
      await ref.putFile(idCardImage);
      idCardPath = ref.fullPath;
    }

    await _db.collection('users').doc(uid).set({
      'role': UserRole.doctor.value,
      'name': fullName,
      'email': email,
      'phone': phone,
      'isActive': true,
      'isVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('doctors').doc(uid).set({
      'gender': (gender == null || gender.trim().isEmpty)
          ? 'male'
          : gender.trim().toLowerCase(),
      'age': int.tryParse(age ?? '30') ?? 30,
      'professionalId': professionalId,
      'verificationStatus': 'pending',
      'idCardImageUrl': idCardPath,
      'reviewedBy': null,
      'reviewedAt': null,
    });
  }

  Future<void> registerCompanion({
    required String name,
    required String email,
    required String password,
    required String companionCode,
  }) async {
    final patient = await _lookupPatientByCompanionCode(companionCode);
    if (patient == null) {
      throw StateError('Invalid companion code.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    await _db.collection('users').doc(uid).set({
      'role': UserRole.companion.value,
      'name': name,
      'email': email,
      'phone': null,
      'isActive': true,
      'isVerified': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('companions').doc(uid).set({
      'linkedPatientId': patient.id,
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
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    String? recordPath;
    if (recordImage != null) {
      final ext = _fileExtension(recordImage);
      final ref = _storage.ref('facility_records/$uid/record$ext');
      await ref.putFile(recordImage);
      recordPath = ref.fullPath;
    }

    await _db.collection('users').doc(uid).set({
      'role': UserRole.facility.value,
      'name': name,
      'email': email,
      'phone': phone,
      'isActive': true,
      'isVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('facilities').doc(uid).set({
      'address': address,
      'facilityType': facilityType,
      'recordImageUrl': recordPath,
      'verificationStatus': 'pending',
    });
  }

  Future<Map<String, dynamic>> getMe() async {
    final uid = _firebase.currentUid;
    final userDoc = await _db.collection('users').doc(uid).get();
    final data = userDoc.data() ?? <String, dynamic>{};
    data['uid'] = uid;

    final role = data['role'];
    if (role == UserRole.patient.value) {
      final patientDoc = await _db.collection('patients').doc(uid).get();
      data.addAll(patientDoc.data() ?? {});
    } else if (role == UserRole.doctor.value) {
      final doctorDoc = await _db.collection('doctors').doc(uid).get();
      data.addAll(doctorDoc.data() ?? {});
    } else if (role == UserRole.companion.value) {
      final companionDoc = await _db.collection('companions').doc(uid).get();
      data.addAll(companionDoc.data() ?? {});
    } else if (role == UserRole.facility.value) {
      final facilityDoc = await _db.collection('facilities').doc(uid).get();
      data.addAll(facilityDoc.data() ?? {});
    }

    return data;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<bool> isAuthenticated() async {
    return _auth.currentUser != null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _lookupPatientByCompanionCode(
    String code,
  ) async {
    final snapshot = await _db
        .collection('patients')
        .where('companionCode', isEqualTo: code)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first;
  }

  Future<String> _generateUniqueCompanionCode() async {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();

    for (var attempt = 0; attempt < 6; attempt++) {
      final code = List.generate(6, (_) => alphabet[random.nextInt(alphabet.length)])
          .join();
      final existing = await _db
          .collection('patients')
          .where('companionCode', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        return code;
      }
    }

    throw StateError('Failed to generate unique companion code.');
  }

  String _fileExtension(File file) {
    final parts = file.path.split('.');
    if (parts.length < 2) return '';
    return '.${parts.last}';
  }
}
