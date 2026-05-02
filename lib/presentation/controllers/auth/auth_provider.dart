import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vitaguard_app/data/repositories/auth/auth_repository.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthController extends _$AuthController {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  StreamSubscription<AuthState>? _authSubscription;

  @override
  AsyncValue<Map<String, dynamic>?> build() {
    // CRITICAL: Keep this provider alive for the entire app session.
    ref.keepAlive();

    debugPrint('[AUTH] AuthController initialized');

    // Subscribe to Supabase auth state changes (reactive auth)
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      _handleAuthStateChange,
      onError: _handleAuthError,
    );

    // Clean up subscription on dispose
    ref.onDispose(() {
      debugPrint('[AUTH] Disposing AuthController subscription');
      _authSubscription?.cancel();
      _authSubscription = null;
    });

    // Initial state: try to load the current user
    _init();

    return const AsyncValue.loading();
  }

  void _handleAuthStateChange(AuthState authState) {
    final event = authState.event;
    final session = authState.session;

    debugPrint('[AUTH] Auth state change: $event, user: ${session?.user.id}');

    if (!ref.mounted) return;

    switch (event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
        if (session != null) {
          debugPrint('[STATE] User signed in, loading user data');
          _loadUserData();
        }
        break;
      case AuthChangeEvent.signedOut:
        debugPrint('[STATE] User signed out, clearing state');
        state = const AsyncValue.data(null);
        break;
      case AuthChangeEvent.passwordRecovery:
        debugPrint('[STATE] Password recovery initiated');
        // Password recovery flow can be handled here (e.g., navigation to reset screen)
        break;
      default:
        break;
    }
  }

  void _handleAuthError(Object error) {
    debugPrint('[ERROR] Auth stream error: $error');
    if (!ref.mounted) return;
    state = AsyncValue.error(error, StackTrace.current);
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _repository.getMe();
      if (ref.mounted) {
        debugPrint('[STATE] User data loaded: ${user['name']}');
        state = AsyncValue.data(user);
      }
    } catch (e, st) {
      debugPrint('[ERROR] Failed to load user data: $e');
      if (ref.mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> _init() async {
    try {
      final user = await _repository.getMe();
      if (ref.mounted) {
        debugPrint('[STATE] Initial user data loaded: ${user['name']}');
        state = AsyncValue.data(user);
      }
    } catch (e, st) {
      debugPrint('[ERROR] Failed to load initial user data: $e');
      if (ref.mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  User? get currentUser => _repository.currentUser;

  String get userName => state.value?['name'] ?? 'User';

  Future<bool> login(String email, String password) async {
    debugPrint('[AUTH] Attempting login for: $email');
    state = const AsyncValue.loading();
    try {
      await _repository.login(email, password);
      if (!ref.mounted) return false;

      final user = await _repository.getMe();
      if (ref.mounted) {
        debugPrint('[STATE] Login successful for: ${user['name']}');
        state = AsyncValue.data(user);
      }
      return true;
    } catch (e, st) {
      debugPrint('[ERROR] Login failed: $e');
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
    debugPrint('[AUTH] Registering patient: $fullName');
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
          debugPrint('[STATE] Patient registered: $fullName');
          state = AsyncValue.data(user);
        }
      }
      return true;
    } catch (e, st) {
      debugPrint('[ERROR] Patient registration failed: $e');
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
    required XFile? idCardImage,
    String? gender,
    String? age,
  }) async {
    debugPrint('[AUTH] Registering doctor: $fullName');
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
          debugPrint('[STATE] Doctor registered: $fullName');
          state = AsyncValue.data(user);
        }
      }
      return true;
    } catch (e, st) {
      debugPrint('[ERROR] Doctor registration failed: $e');
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
    debugPrint('[AUTH] Registering companion: $name');
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
          debugPrint('[STATE] Companion registered: $name');
          state = AsyncValue.data(user);
        }
      }
      return true;
    } catch (e, st) {
      debugPrint('[ERROR] Companion registration failed: $e');
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
    required XFile? recordImage,
  }) async {
    debugPrint('[AUTH] Registering facility: $name');
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
          debugPrint('[STATE] Facility registered: $name');
          state = AsyncValue.data(user);
        }
      }
      return true;
    } catch (e, st) {
      debugPrint('[ERROR] Facility registration failed: $e');
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
    debugPrint('[AUTH] Logging out user');
    await _repository.logout();
    if (!ref.mounted) return;

    // Clear state
    state = const AsyncValue.data(null);

    // Invalidate all user-scoped providers to prevent stale data
    debugPrint('[STATE] Invalidating all providers on logout');
    ref.invalidateSelf();
  }
}
