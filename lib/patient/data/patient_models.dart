class MedicalHistory {
  MedicalHistory({
    this.allergies,
    this.medications,
    this.chronicDiseases,
    this.surgeries,
    this.notes,
  });

  final String? allergies;
  final String? medications;
  final String? chronicDiseases;
  final String? surgeries;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'allergies': allergies ?? "",
    'medications': medications ?? "",
    'chronic_diseases': chronicDiseases ?? "",
    'surgeries': surgeries ?? "",
    'notes': notes ?? "",
  };

  factory MedicalHistory.fromJson(Map<String, dynamic> json) {
    return MedicalHistory(
      allergies: json['allergies'],
      medications: json['medications'],
      chronicDiseases: json['chronic_diseases'],
      surgeries: json['surgeries'],
      notes: json['notes'],
    );
  }
}

class DailyReport {
  DailyReport({
    required this.heartRate,
    required this.oxygenLevel,
    required this.temperature,
    required this.bloodPressure,
    this.reportDate,
  });

  final double heartRate;
  final double oxygenLevel;
  final double temperature;
  final String bloodPressure;
  final DateTime? reportDate;

  Map<String, dynamic> toJson() {
    final date = reportDate ?? DateTime.now();
    return {
      'report_date':
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'heart_rate': heartRate,
      'oxygen_level': oxygenLevel,
      'temperature': temperature,
      'blood_pressure': bloodPressure,
      'tasks_activities': "-", // Backend expects this
      'notes': "",
    };
  }
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
