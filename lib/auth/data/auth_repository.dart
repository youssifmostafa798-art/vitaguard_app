import 'package:dio/dio.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage_service.dart';
import 'auth_models.dart';

class AuthRepository {
  final Dio _dio = DioClient().dio;
  final _storage = SecureStorageService();

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'username':
              email, // Backend uses OAuth2PasswordRequestForm which expects 'username'
          'password': password,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _storage.saveTokens(
        access: authResponse.accessToken,
        refresh: authResponse.refreshToken,
      );
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerPatient({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    String? gender,
    String? age,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.registerPatient,
        data: {
          'name': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'gender': gender ?? "Male",
          'age': int.tryParse(age ?? "0") ?? 0,
          'chronic_diseases': "",
          'medications': "",
          'allergies': "",
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get(ApiEndpoints.profile);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getAccessToken();
    return token != null;
  }
}
