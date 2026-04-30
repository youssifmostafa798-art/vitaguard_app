import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vitaguard_app/data/repositories/auth/auth_repository.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthController extends _$AuthController {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AsyncValue<Map<String, dynamic>?> build() {
    // Initial state: try to load the current user
    _init();
    return const AsyncValue.loading();
  }

  Future<void> _init() async {
    try {
      final user = await _repository.getMe();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  User? get currentUser => _repository.currentUser;

  String get userName => state.value?['name'] ?? 'User';

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repository.login(email, password);
      final user = await _repository.getMe();
      state = AsyncValue.data(user);
      return true;
    } catch (e, st) {
      debugPrint('Auth login error: $e');
      state = AsyncValue.error(ErrorMapper.map(e), st);
      return false;
    }
  }

  Future<bool> registerPatient({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    String? gender,
    String? age,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.registerPatient(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        gender: gender,
        age: age,
      );
      if (response.session != null) {
        final user = await _repository.getMe();
        state = AsyncValue.data(user);
      }
      return true;
    } catch (e, st) {
      debugPrint('Auth register patient error: $e');
      state = AsyncValue.error(ErrorMapper.map(e), st);
      return false;
    }
  }

  Future<bool> registerDoctor({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String professionalId,
    required File? idCardImage,
    String? gender,
    String? age,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.registerDoctor(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        professionalId: professionalId,
        idCardImage: idCardImage,
        gender: gender,
        age: age,
      );
      if (response.session != null) {
        final user = await _repository.getMe();
        state = AsyncValue.data(user);
      }
      return true;
    } catch (e, st) {
      debugPrint('Auth register doctor error: $e');
      state = AsyncValue.error(ErrorMapper.map(e), st);
      return false;
    }
  }

  Future<bool> registerCompanion({
    required String name,
    required String email,
    required String password,
    required String companionCode,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.registerCompanion(
        name: name,
        email: email,
        password: password,
        companionCode: companionCode,
      );
      if (response.session != null) {
        final user = await _repository.getMe();
        state = AsyncValue.data(user);
      }
      return true;
    } catch (e, st) {
      debugPrint('Auth register companion error: $e');
      state = AsyncValue.error(ErrorMapper.map(e), st);
      return false;
    }
  }

  Future<bool> registerFacility({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String facilityType,
    required File? recordImage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.registerFacility(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
        facilityType: facilityType,
        recordImage: recordImage,
      );
      if (response.session != null) {
        final user = await _repository.getMe();
        state = AsyncValue.data(user);
      }
      return true;
    } catch (e, st) {
      debugPrint('Auth register facility error: $e');
      state = AsyncValue.error(ErrorMapper.map(e), st);
      return false;
    }
  }

  Future<bool> isAuthenticated() async {
    return await _repository.isAuthenticated();
  }

  Future<String?> getUserRole() async {
    if (state.hasValue && state.value != null) {
      return state.value!['role'] as String?;
    }
    try {
      final user = await _repository.getMe();
      state = AsyncValue.data(user);
      return user['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}
