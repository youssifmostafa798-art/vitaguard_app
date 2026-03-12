import 'dart:io';
import 'package:dio/dio.dart';
import 'package:vitaguard_app/core/network/api_endpoints.dart';
import 'package:vitaguard_app/core/network/dio_client.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';

class PatientRepository {
  final Dio _dio = DioClient().dio;

  Future<void> submitDailyReport(DailyReport report) async {
    try {
      await _dio.post(ApiEndpoints.dailyReports, data: report.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMedicalHistory(MedicalHistory history) async {
    try {
      await _dio.put(ApiEndpoints.medicalHistory, data: history.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<MedicalHistory> getMedicalHistory() async {
    try {
      final response = await _dio.get(ApiEndpoints.medicalHistory);
      if (response.data is List && (response.data as List).isNotEmpty) {
        return MedicalHistory.fromJson(response.data[0]);
      }
      return MedicalHistory(
        chronicDiseases: "",
        medications: "",
        allergies: "",
        surgeries: "",
        notes: "",
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<XRayResult> analyzeXRay(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        ApiEndpoints.xrayAnalyze,
        data: formData,
      );
      return XRayResult.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getCompanionCode() async {
    try {
      final response = await _dio.get(ApiEndpoints.generateCompanionCode);
      return response.data['companion_code'] as String;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadMedicalDocument(File documentFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          documentFile.path,
          filename: documentFile.path.split('/').last,
        ),
      });

      await _dio.post(
        ApiEndpoints.patientDocuments,
        data: formData,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String> regenerateCompanionCode() async {
    try {
      final response = await _dio.post(ApiEndpoints.companionCodeRegenerate);
      return response.data['companion_code'] as String;
    } catch (e) {
      rethrow;
    }
  }
}
