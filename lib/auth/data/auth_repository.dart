import 'package:flutter/material.dart';
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
        data: {'email': email, 'password': password},
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
      final payload = {
        'name': fullName,
        'email': email,
        'password': password,
        'phone': phone,
        'gender': (gender == null || gender.trim().isEmpty)
            ? "male"
            : gender.trim().toLowerCase(),
        'age': int.tryParse(age ?? "20") ?? 20,
        'chronic_diseases': "",
        'medications': "",
        'allergies': "",
      };
      debugPrint('Registering Patient: $payload');
      await _dio.post(ApiEndpoints.registerPatient, data: payload);
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
      final payload = {
        'name': fullName,
        'email': email,
        'password': password,
        'phone': phone,
        'professional_id': professionalId,
        'gender': (gender == null || gender.trim().isEmpty)
            ? "male"
            : gender.trim().toLowerCase(),
        'age': int.tryParse(age ?? "30") ?? 30,
      };
      debugPrint('Registering Doctor: $payload');
      await _dio.post(ApiEndpoints.registerDoctor, data: payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerCompanion({
    required String name,
    required String companionCode,
  }) async {
    try {
      final payload = {'name': name, 'companion_code': companionCode};
      debugPrint('Registering Companion: $payload');
      await _dio.post(ApiEndpoints.registerCompanion, data: payload);
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
      final payload = {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'address': address,
        'facility_type': facilityType,
      };
      debugPrint('Registering Facility: $payload');
      await _dio.post(ApiEndpoints.registerFacility, data: payload);
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
