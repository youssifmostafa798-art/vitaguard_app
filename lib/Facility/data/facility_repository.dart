import 'dart:io';
import 'package:dio/dio.dart';
import 'package:vitaguard_app/core/network/api_endpoints.dart';
import 'package:vitaguard_app/core/network/dio_client.dart';

class FacilityRepository {
  final Dio _dio = DioClient().dio;

  Future<void> uploadMedicalTest({
    String? patientId,
    String? patientPhone,
    required String testType,
    required String filePath,
    String? notes,
  }) async {
    try {
      final formData = FormData.fromMap({
        'patient_id': ?patientId,
        'patient_phone': ?patientPhone,
        'test_type': testType,
        'file': await MultipartFile.fromFile(filePath),
        'notes': notes,
      });
      await _dio.post(ApiEndpoints.facilityTests, data: formData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createOffer({
    required String title,
    required String description,
    File? image,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        if (image != null)
          'image': await MultipartFile.fromFile(
            image.path,
            filename: image.path.split('/').last,
          ),
      });
      await _dio.post(ApiEndpoints.facilityOffers, data: formData);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getAppointments() async {
    try {
      final response = await _dio.get(ApiEndpoints.facilityAppointments);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
