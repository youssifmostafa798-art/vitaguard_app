import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:vitaguard_app/core/firebase/firebase_service.dart';

class FacilityRepository {
  final FirebaseService _firebase = FirebaseService.instance;

  FirebaseFirestore get _db => _firebase.firestore;
  FirebaseStorage get _storage => _firebase.storage;
  String get _uid => _firebase.currentUid;

  Future<void> uploadMedicalTest({
    String? patientId,
    String? patientPhone,
    required String testType,
    required String filePath,
    String? notes,
  }) async {
    String? resolvedPatientId = patientId;

    if (resolvedPatientId == null && patientPhone != null && patientPhone.isNotEmpty) {
      final userSnapshot = await _db
          .collection('users')
          .where('phone', isEqualTo: patientPhone)
          .where('role', isEqualTo: 'patient')
          .limit(1)
          .get();
      if (userSnapshot.docs.isNotEmpty) {
        resolvedPatientId = userSnapshot.docs.first.id;
      }
    }

    final docRef = _db
        .collection('facilities')
        .doc(_uid)
        .collection('tests')
        .doc();

    final file = File(filePath);
    final ext = _fileExtension(file);
    final ref = _storage.ref('lab_reports/$_uid/${docRef.id}$ext');
    await ref.putFile(file);

    await docRef.set({
      'id': docRef.id,
      'facilityId': _uid,
      'patientId': resolvedPatientId,
      'testType': testType,
      'filePath': ref.fullPath,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createOffer({
    required String title,
    required String description,
    File? image,
  }) async {
    final docRef = _db
        .collection('facilities')
        .doc(_uid)
        .collection('offers')
        .doc();

    String? imagePath;
    if (image != null) {
      final ext = _fileExtension(image);
      final ref = _storage.ref('lab_offers/$_uid/${docRef.id}$ext');
      await ref.putFile(image);
      imagePath = ref.fullPath;
    }

    await docRef.set({
      'id': docRef.id,
      'facilityId': _uid,
      'title': title,
      'description': description,
      'imageUrl': imagePath,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<dynamic>> getAppointments() async {
    final snapshot = await _db
        .collection('facilities')
        .doc(_uid)
        .collection('appointments')
        .orderBy('scheduledAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  String _fileExtension(File file) {
    final parts = file.path.split('.');
    if (parts.length < 2) return '';
    return '.${parts.last.toLowerCase()}';
  }
}
