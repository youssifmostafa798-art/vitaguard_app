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
    // CRITICAL: Keep this provider alive for the entire app session.
    // Without keepAlive(), Riverpod auto-disposes the provider whenever no widget
    // is actively *watching* it (e.g., between async gaps in SplashScreen).
    // Accessing `state` on a disposed notifier throws:
    //   "Cannot use the Ref of authControllerProvider after it has been disposed"
    ref.keepAlive();

    // Initial state: try to load the current user
    _init();

    // Set up disposal callback
    ref.onDispose(() {
      // Cleanup if needed
    });

    return const AsyncValue.loading();
  }

  Future<void> _init() async {
    try {
      final user = await _repository.getMe();
      if (ref.mounted) {
        state = AsyncValue.data(user);
      }
    } catch (e, st) {
      if (ref.mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  User? get currentUser => _repository.currentUser;

  String get userName => state.value?['name'] ?? 'User';

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repository.login(email, password);
      if (!ref.mounted) return false;

      final user = await _repository.getMe();
      if (ref.mounted) {
        state = AsyncValue.data(user);
      }
      return true;
    } catch (e, st) {
      debugPrint('Auth login error: $e');
      if (ref.mounted) {
        state = AsyncValue.error(ErrorMapper.map(e), st);
      }
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
      if (!ref.mounted) return false;

      if (response.session != null) {
        final user = await _repository.getMe();
        if (ref.mounted) {
          state = AsyncValue.data(user);
        }
      }
      return true;
    } catch (e, st) {
      debugPrint('Auth register patient error: $e');
      if (ref.mounted) {
        state = AsyncValue.error(ErrorMapper.map(e), st);
      }
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
      if (!ref.mounted) return false;

      if (response.session != null) {
        final user = await _repository.getMe();
        if (ref.mounted) {
          state = AsyncValue.data(user);
        }
      }
      return true;
    } catch (e, st) {
      debugPrint('Auth register doctor error: $e');
      if (ref.mounted) {
        state = AsyncValue.error(ErrorMapper.map(e), st);
      }
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
      if (!ref.mounted) return false;

      if (response.session != null) {
        final user = await _repository.getMe();
        if (ref.mounted) {
          state = AsyncValue.data(user);
        }
      }
      return true;
    } catch (e, st) {
      debugPrint('Auth register companion error: $e');
      if (ref.mounted) {
        state = AsyncValue.error(ErrorMapper.map(e), st);
      }
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
      if (!ref.mounted) return false;

      if (response.session != null) {
        final user = await _repository.getMe();
        if (ref.mounted) {
          state = AsyncValue.data(user);
        }
      }
      return true;
    } catch (e, st) {
      debugPrint('Auth register facility error: $e');
      if (ref.mounted) {
        state = AsyncValue.error(ErrorMapper.map(e), st);
      }
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
      if (!ref.mounted) return null;

      state = AsyncValue.data(user);
      return user['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    if (!ref.mounted) return;
    state = const AsyncValue.data(null);
  }
}
