import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:vitaguard_app/core/ai/xray_inference_service.dart';
import 'package:vitaguard_app/core/firebase/firebase_service.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';

class PatientRepository {
  final FirebaseService _firebase = FirebaseService.instance;

  FirebaseFirestore get _db => _firebase.firestore;
  FirebaseStorage get _storage => _firebase.storage;

  String get _uid => _firebase.currentUid;

  Future<void> submitDailyReport(DailyReport report) async {
    final data = report.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();

    await _db
        .collection('patients')
        .doc(_uid)
        .collection('daily_reports')
        .add(data);
  }

  Future<void> updateMedicalHistory(MedicalHistory history) async {
    final data = history.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _db
        .collection('patients')
        .doc(_uid)
        .collection('medical_history')
        .doc('current')
        .set(data, SetOptions(merge: true));
  }

  Future<MedicalHistory> getMedicalHistory() async {
    final doc = await _db
        .collection('patients')
        .doc(_uid)
        .collection('medical_history')
        .doc('current')
        .get();

    if (!doc.exists || doc.data() == null) {
      return MedicalHistory(
        chronicDiseases: '',
        medications: '',
        allergies: '',
        surgeries: '',
        notes: '',
      );
    }

    return MedicalHistory.fromMap(doc.data()!);
  }

  Future<XRayResult> analyzeXRay(File imageFile) async {
    final result = await XrayInferenceService.instance.analyze(imageFile);

    final docRef = _db
        .collection('patients')
        .doc(_uid)
        .collection('xray_results')
        .doc();

    String? storagePath;
    if (result.isValid) {
      final ext = _fileExtension(imageFile);
      final ref = _storage.ref('xray_results/$_uid/${docRef.id}$ext');
      await ref.putFile(imageFile);
      storagePath = ref.fullPath;
    }

    final data = result.toMap();
    data['imagePath'] = storagePath;
    data['createdAt'] = FieldValue.serverTimestamp();

    await docRef.set(data);

    return XRayResult(
      isValid: result.isValid,
      prediction: result.prediction,
      confidence: result.confidence,
      reportText: result.reportText,
      imagePath: storagePath,
    );
  }

  Future<void> uploadMedicalDocument(File documentFile) async {
    final docRef = _db
        .collection('patients')
        .doc(_uid)
        .collection('documents')
        .doc();

    final ext = _fileExtension(documentFile);
    final ref = _storage.ref('medical_records/$_uid/${docRef.id}$ext');
    await ref.putFile(documentFile);

    await docRef.set({
      'id': docRef.id,
      'patientId': _uid,
      'fileUrl': ref.fullPath,
      'documentType': ext == '.pdf' ? 'pdf' : 'image',
      'originalFilename': documentFile.path.split('/').last,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> getCompanionCode() async {
    final doc = await _db.collection('patients').doc(_uid).get();
    final data = doc.data();
    final code = data?['companionCode'];
    if (code is String && code.isNotEmpty) {
      return code;
    }

    final newCode = await _generateUniqueCompanionCode();
    await _db.collection('patients').doc(_uid).set({
      'companionCode': newCode,
    }, SetOptions(merge: true));
    return newCode;
  }

  Future<String> regenerateCompanionCode() async {
    final newCode = await _generateUniqueCompanionCode();
    await _db.collection('patients').doc(_uid).set({
      'companionCode': newCode,
    }, SetOptions(merge: true));
    return newCode;
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
    return '.${parts.last.toLowerCase()}';
  }
}
