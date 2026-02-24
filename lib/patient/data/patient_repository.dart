import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import 'patient_models.dart';

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
      return MedicalHistory.fromJson(response.data);
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
}
