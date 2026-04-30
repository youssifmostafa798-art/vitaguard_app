class PatientLiveVitals {
  final String id;
  final String patientId;
  final int bpm;
  final int spo2;
  final double temperature;
  final String? deviceStatus;
  final DateTime recordedAt;

  const PatientLiveVitals({
    required this.id,
    required this.patientId,
    required this.bpm,
    required this.spo2,
    required this.temperature,
    this.deviceStatus,
    required this.recordedAt,
  });

  factory PatientLiveVitals.fromJson(Map<String, dynamic> json) {
    return PatientLiveVitals(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      bpm: (json['bpm'] as num?)?.toInt() ?? 0,
      spo2: (json['spo2'] as num?)?.toInt() ?? 0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      deviceStatus: json['device_status']?.toString(),
      recordedAt: _parseDate(json['recorded_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'bpm': bpm,
      'spo2': spo2,
      'temperature': temperature,
      'device_status': deviceStatus,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
