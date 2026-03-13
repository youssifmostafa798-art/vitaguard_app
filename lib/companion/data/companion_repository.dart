import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:vitaguard_app/core/firebase/firebase_service.dart';

class CompanionRepository {
  final FirebaseService _firebase = FirebaseService.instance;

  FirebaseFirestore get _db => _firebase.firestore;
  String get _uid => _firebase.currentUid;

  Future<void> linkPatient(String code) async {
    final snapshot = await _db
        .collection('patients')
        .where('companionCode', isEqualTo: code)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw StateError('Invalid companion code.');
    }

    final patientId = snapshot.docs.first.id;
    await _db.collection('companions').doc(_uid).set({
      'linkedPatientId': patientId,
    }, SetOptions(merge: true));
  }

  Future<dynamic> getPatientStatus() async {
    final companionDoc = await _db.collection('companions').doc(_uid).get();
    final linkedPatientId = companionDoc.data()?['linkedPatientId'];
    if (linkedPatientId == null) {
      throw StateError('No linked patient found.');
    }

    final patientDoc = await _db.collection('patients').doc(linkedPatientId).get();
    final userDoc = await _db.collection('users').doc(linkedPatientId).get();

    return {
      'patient_id': linkedPatientId,
      'name': userDoc.data()?['name'] ?? 'Unknown',
      'age': patientDoc.data()?['age'],
      'gender': patientDoc.data()?['gender'],
    };
  }
}
