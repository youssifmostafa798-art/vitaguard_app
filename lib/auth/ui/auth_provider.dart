import 'package:flutter/material.dart';
import '../data/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _currentUser;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get currentUser => _currentUser;
  String get userName =>
      _currentUser?['full_name'] ?? _currentUser?['name'] ?? 'User';

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
      _currentUser = await _repository.getMe();
      return _currentUser?['role'];
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


