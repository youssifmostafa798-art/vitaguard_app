class MedicalHistory {
  final String? allergies;
  final String? medications;
  final String? pastConditions;
  final String? surgeries;
  final String? notes;

  MedicalHistory({
    this.allergies,
    this.medications,
    this.pastConditions,
    this.surgeries,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'allergies': allergies,
    'medications': medications,
    'past_conditions': pastConditions,
    'surgeries': surgeries,
    'notes': notes,
  };

  factory MedicalHistory.fromJson(Map<String, dynamic> json) {
    return MedicalHistory(
      allergies: json['allergies'],
      medications: json['medications'],
      pastConditions: json['past_conditions'],
      surgeries: json['surgeries'],
      notes: json['notes'],
    );
  }
}

class DailyReport {
  final double heartRate;
  final double oxygenLevel;
  final double temperature;
  final String bloodPressure;

  DailyReport({
    required this.heartRate,
    required this.oxygenLevel,
    required this.temperature,
    required this.bloodPressure,
  });

  Map<String, dynamic> toJson() => {
    'heart_rate': heartRate,
    'oxygen_level': oxygenLevel,
    'temperature': temperature,
    'blood_pressure': bloodPressure,
  };
}

class XRayResult {
  final bool isValid;
  final String? prediction;
  final double? confidence;
  final String? reportText;
  final String? imagePath;

  XRayResult({
    required this.isValid,
    this.prediction,
    this.confidence,
    this.reportText,
    this.imagePath,
  });

  factory XRayResult.fromJson(Map<String, dynamic> json) {
    return XRayResult(
      isValid: json['is_valid'] ?? false,
      prediction: json['prediction'],
      confidence: (json['confidence'] as num?)?.toDouble(),
      reportText: json['report_text'],
      imagePath: json['image_path'],
    );
  }
}
