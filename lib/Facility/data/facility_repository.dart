import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';

class FacilityRepository {
  final Dio _dio = DioClient().dio;

  Future<void> uploadMedicalTest({
    required String patientId,
    required String testType,
    required String filePath,
    String? notes,
  }) async {
    try {
      final formData = FormData.fromMap({
        'patient_id': patientId,
        'test_type': testType,
        'file': await MultipartFile.fromFile(filePath),
        'notes': notes,
      });
      await _dio.post(ApiEndpoints.facilityTests, data: formData);
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



