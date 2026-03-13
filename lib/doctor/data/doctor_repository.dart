import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vitaguard_app/core/firebase/firebase_service.dart';

class DoctorRepository {
  final FirebaseService _firebase = FirebaseService.instance;

  FirebaseFirestore get _db => _firebase.firestore;
  String get _uid => _firebase.currentUid;

  Future<List<Map<String, dynamic>>> getAssignedPatients() async {
    final query = await _db
        .collection('patients')
        .where('assignedDoctorId', isEqualTo: _uid)
        .get();

    final results = <Map<String, dynamic>>[];
    for (final doc in query.docs) {
      final patientId = doc.id;
      final patientData = doc.data();
      final userDoc = await _db.collection('users').doc(patientId).get();
      final userData = userDoc.data() ?? {};

      results.add({
        'patient_id': patientId,
        'name': userData['name'] ?? 'Unknown',
        'age': patientData['age'],
        'gender': patientData['gender'],
      });
    }

    return results;
  }

  Future<void> sendFeedback({
    required String patientId,
    required String feedbackText,
    String? xrayResultId,
  }) async {
    await _db
        .collection('patients')
        .doc(patientId)
        .collection('medical_feedback')
        .add({
      'doctorId': _uid,
      'patientId': patientId,
      'xrayResultId': xrayResultId,
      'feedbackText': feedbackText,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> getVerificationStatus() async {
    final doc = await _db.collection('doctors').doc(_uid).get();
    final data = doc.data() ?? {};
    return {
      'verificationStatus': data['verificationStatus'] ?? 'pending',
      'idCardImageUrl': data['idCardImageUrl'],
      'reviewedAt': data['reviewedAt'],
    };
  }
}
