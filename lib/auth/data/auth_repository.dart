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

  Future<AuthResponse> loginCompanion(String name, String code) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.login}/companion',
        data: {'name': name, 'companion_code': code},
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
          'gender': gender ?? "male",
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

  Future<void> registerDoctor({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String professionalId,
    String? gender,
    String? age,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.registerDoctor,
        data: {
          'name': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'professional_id': professionalId,
          'gender': gender ?? "male",
          'age': int.tryParse(age ?? "0") ?? 0,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerCompanion({
    required String name,
    required String companionCode,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.registerCompanion,
        data: {'name': name, 'companion_code': companionCode},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerFacility({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String facilityType,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.registerFacility,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'address': address,
          'facility_type': facilityType,
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
