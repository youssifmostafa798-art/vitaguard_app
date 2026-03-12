import 'dart:io';
import 'package:flutter/foundation.dart';

class BackendManager {
  static final BackendManager _instance = BackendManager._internal();
  factory BackendManager() => _instance;
  BackendManager._internal();

  Process? _backendProcess;

  /// Attempts to start the backend automatically on Desktop platforms.
  Future<void> autoStartBackend() async {
    if (kIsWeb) return; // Cannot run processes on Web

    if (Platform.isWindows) {
      await _startWindowsBackend();
    }
    // Mobile platforms (Android/iOS) cannot run the Python backend locally.
    // They must connect to a remote server IP.
  }

  Future<void> _startWindowsBackend() async {
    try {
      // Check if backend is already running (simple check)
      // This is best handled by the HealthProvider, but we can try to launch
      // the .bat file in detached mode.
      
      final String batPath = 'run_vitaguard_backend.bat';
      
      if (await File(batPath).exists()) {
        debugPrint('BackendManager: Starting backend via batch file...');
        
        // Use shell execute to run the batch file in the background
        _backendProcess = await Process.start(
          'cmd',
          ['/c', 'start', '/min', batPath],
          runInShell: true,
          mode: ProcessStartMode.detached,
        );
        
        debugPrint('BackendManager: Backend launch triggered.');
      } else {
        debugPrint('BackendManager: run_vitaguard_backend.bat not found in root.');
      }
    } catch (e) {
      debugPrint('BackendManager Error: $e');
    }
  }

  void dispose() {
    _backendProcess?.kill();
  }
}
