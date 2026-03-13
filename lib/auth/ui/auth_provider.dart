import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vitaguard_app/auth/data/auth_repository.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _currentUser;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get currentUser => _currentUser;
  String get userName => _currentUser?['name'] ?? 'User';

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      await _repository.login(email, password);
      _currentUser = await _repository.getMe();
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Auth login error: $e');
      _error = ErrorMapper.map(e);
      _setLoading(false);
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
    _setLoading(true);
    try {
      await _repository.registerPatient(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        gender: gender,
        age: age,
      );
      _currentUser = await _repository.getMe();
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Auth register patient error: $e');
      _error = ErrorMapper.map(e);
      _setLoading(false);
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
    _setLoading(true);
    try {
      await _repository.registerDoctor(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        professionalId: professionalId,
        idCardImage: idCardImage,
        gender: gender,
        age: age,
      );
      _currentUser = await _repository.getMe();
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Auth register doctor error: $e');
      _error = ErrorMapper.map(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerCompanion({
    required String name,
    required String email,
    required String password,
    required String companionCode,
  }) async {
    _setLoading(true);
    try {
      await _repository.registerCompanion(
        name: name,
        email: email,
        password: password,
        companionCode: companionCode,
      );
      _currentUser = await _repository.getMe();
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Auth register companion error: $e');
      _error = ErrorMapper.map(e);
      _setLoading(false);
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
    _setLoading(true);
    try {
      await _repository.registerFacility(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
        facilityType: facilityType,
        recordImage: recordImage,
      );
      _currentUser = await _repository.getMe();
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Auth register facility error: $e');
      _error = ErrorMapper.map(e);
      _setLoading(false);
      return false;
    }
  }

  Future<String?> getUserRole() async {
    final cachedRole = _currentUser?['role'];
    if (cachedRole is String && cachedRole.isNotEmpty) {
      return cachedRole;
    }

    try {
      _currentUser = await _repository.getMe();
      return _currentUser?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) {
      _error = null;
    }
    notifyListeners();
  }
}
