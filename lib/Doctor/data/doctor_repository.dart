import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';

class DoctorRepository {
  final Dio _dio = DioClient().dio;

  Future<List<dynamic>> getAssignedPatients() async {
    try {
      final response = await _dio.get(ApiEndpoints.assignedPatients);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendFeedback({
    required String patientId,
    required String feedbackText,
    String? severity,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.postFeedback,
        data: {
          'patient_id': patientId,
          'message': feedbackText,
          'severity': severity ?? 'normal',
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}



