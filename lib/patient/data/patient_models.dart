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

  Map<String, dynamic> toMap() => {
    'allergies': allergies ?? "",
    'medications': medications ?? "",
    'chronicDiseases': chronicDiseases ?? "",
    'surgeries': surgeries ?? "",
    'notes': notes ?? "",
  };

  factory MedicalHistory.fromMap(Map<String, dynamic> json) {
    return MedicalHistory(
      allergies: json['allergies'] ?? "",
      medications: json['medications'] ?? "",
      chronicDiseases:
          json['chronicDiseases'] ?? json['chronic_diseases'] ?? "",
      surgeries: json['surgeries'] ?? "",
      notes: json['notes'] ?? "",
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

  Map<String, dynamic> toMap() {
    final date = reportDate ?? DateTime.now();
    return {
      'reportDate': date,
      'heartRate': heartRate,
      'oxygenLevel': oxygenLevel,
      'temperature': temperature,
      'bloodPressure': bloodPressure,
      'tasksActivities': "-",
      'notes': "",
    };
  }
}

class XRayResult {
  final String? id;
  final bool isValid;
  final String? prediction;
  final double? confidence;
  final String? reportText;
  final String? imagePath;
  final double? probNormal;
  final double? probPneumonia;

  XRayResult({
    this.id,
    required this.isValid,
    this.prediction,
    this.confidence,
    this.reportText,
    this.imagePath,
    this.probNormal,
    this.probPneumonia,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isValid': isValid,
      'prediction': prediction,
      'confidence': confidence,
      'reportText': reportText,
      'imagePath': imagePath,
      'prob_normal': probNormal,
      'prob_pneumonia': probPneumonia,
    };
  }

  factory XRayResult.fromMap(Map<String, dynamic> json) {
    return XRayResult(
      id: json['id'],
      isValid: json['isValid'] ?? json['is_valid'] ?? false,
      prediction: json['prediction'],
      confidence: (json['confidence'] as num?)?.toDouble(),
      reportText: json['reportText'] ?? json['report_text'],
      imagePath: json['imagePath'] ?? json['image_path'],
      probNormal: (json['prob_normal'] as num?)?.toDouble(),
      probPneumonia: (json['prob_pneumonia'] as num?)?.toDouble(),
    );
  }
}

class MedicalDocument {
  final String id;
  final String patientId;
  final String fileUrl;
  final String documentType;
  final String originalFilename;
  final DateTime uploadedAt;

  MedicalDocument({
    required this.id,
    required this.patientId,
    required this.fileUrl,
    required this.documentType,
    required this.originalFilename,
    required this.uploadedAt,
  });

  factory MedicalDocument.fromMap(Map<String, dynamic> json) {
    DateTime uploadedAt;
    final rawUploaded = json['uploadedAt'] ?? json['uploaded_at'];
    if (rawUploaded is DateTime) {
      uploadedAt = rawUploaded;
    } else {
      uploadedAt =
          DateTime.tryParse(rawUploaded?.toString() ?? '') ?? DateTime.now();
    }

    return MedicalDocument(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? json['patient_id'] ?? '',
      fileUrl: json['fileUrl'] ?? json['file_url'] ?? json['file_path'] ?? '',
      documentType: json['documentType'] ?? json['document_type'] ?? '',
      originalFilename:
          json['originalFilename'] ?? json['original_filename'] ?? '',
      uploadedAt: uploadedAt,
    );
  }
}
