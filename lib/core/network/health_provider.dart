import 'package:flutter/material.dart';
import 'health_repository.dart';

class HealthProvider with ChangeNotifier {
  final HealthRepository _repository = HealthRepository();
  bool _isAiOnline = false;
  String _aiMessage = "Checking AI status...";

  bool get isAiOnline => _isAiOnline;
  String get aiMessage => _aiMessage;

  HealthProvider() {
    checkHealth();
  }

  Future<void> checkHealth() async {
    final health = await _repository.getAiHealth();
    if (health['status'] == 'healthy') {
      _isAiOnline = true;
      _aiMessage = "AI Models Online";
    } else {
      _isAiOnline = false;
      _aiMessage = "AI Models Offline or Error";
    }
    notifyListeners();
  }
}
