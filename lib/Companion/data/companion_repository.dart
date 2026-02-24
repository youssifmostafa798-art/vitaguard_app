import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';

class CompanionRepository {
  final Dio _dio = DioClient().dio;

  Future<void> linkPatient(String code) async {
    try {
      await _dio.post(ApiEndpoints.companionLink, data: {'code': code});
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getPatientStatus() async {
    try {
      final response = await _dio.get(ApiEndpoints.companionPatient);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
