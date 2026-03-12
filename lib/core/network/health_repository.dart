import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';

class HealthRepository {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>> getAiHealth() async {
    try {
      final response = await _dio.get("/health/ai");
      return response.data;
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
