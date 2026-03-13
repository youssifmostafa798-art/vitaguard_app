import 'package:cloud_firestore/cloud_firestore.dart';

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
      chronicDiseases: json['chronicDiseases'] ?? json['chronic_diseases'] ?? "",
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

  Map<String, dynamic> toMap() {
    return {
      'isValid': isValid,
      'prediction': prediction,
      'confidence': confidence,
      'reportText': reportText,
      'imagePath': imagePath,
    };
  }

  factory XRayResult.fromMap(Map<String, dynamic> json) {
    return XRayResult(
      isValid: json['isValid'] ?? json['is_valid'] ?? false,
      prediction: json['prediction'],
      confidence: (json['confidence'] as num?)?.toDouble(),
      reportText: json['reportText'] ?? json['report_text'],
      imagePath: json['imagePath'] ?? json['image_path'],
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
    final rawUploaded = json['uploadedAt'];
    if (rawUploaded is Timestamp) {
      uploadedAt = rawUploaded.toDate();
    } else if (rawUploaded is DateTime) {
      uploadedAt = rawUploaded;
    } else {
      uploadedAt = DateTime.tryParse(rawUploaded?.toString() ?? '') ?? DateTime.now();
    }

    return MedicalDocument(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? json['patient_id'] ?? '',
      fileUrl: json['fileUrl'] ?? json['file_url'] ?? '',
      documentType: json['documentType'] ?? json['document_type'] ?? '',
      originalFilename: json['originalFilename'] ?? json['original_filename'] ?? '',
      uploadedAt: uploadedAt,
    );
  }
}
