import 'package:flutter/material.dart';
import '../data/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _handleError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerPatient({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.registerPatient(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _handleError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> getUserRole() async {
    try {
      final data = await _repository.getMe();
      return data['role'];
    } catch (e) {
      return null;
    }
  }

  String _handleError(dynamic e) {
    if (e is Exception) {
      return e.toString().replaceAll('Exception: ', '');
    }
    return 'An unexpected error occurred';
  }
}
