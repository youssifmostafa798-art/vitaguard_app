class LinkedPatientStatus {
  const LinkedPatientStatus({
    required this.patientId,
    required this.name,
    this.age,
    this.gender,
  });

  final String patientId;
  final String name;
  final dynamic age;
  final String? gender;

  factory LinkedPatientStatus.fromMap(Map<String, dynamic> json) {
    return LinkedPatientStatus(
      patientId: json['patient_id'] as String,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Unknown',
      age: json['age'],
      gender: json['gender'] as String?,
    );
  }
}
