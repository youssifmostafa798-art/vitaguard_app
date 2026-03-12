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
      final String projectRoot = Directory.current.path;
      final String backendDir = '$projectRoot/backend';
      
      if (!await Directory(backendDir).exists()) {
        debugPrint('BackendManager: Backend directory not found at $backendDir');
        return;
      }

      debugPrint('BackendManager: Orchestrating backend startup...');

      // 1. Detect and sync dependencies
      String? pythonPath;
      bool useUv = false;
      
      try {
        final uvCheck = await Process.run('where', ['uv'], runInShell: true);
        if (uvCheck.exitCode == 0) {
          debugPrint('BackendManager: Found "uv". Syncing dependencies...');
          await Process.run('uv', ['sync'], workingDirectory: backendDir, runInShell: true);
          useUv = true;
          pythonPath = 'uv';
        }
      } catch (_) {}

      if (!useUv) {
        debugPrint('BackendManager: "uv" not found. Falling back to .venv...');
        final venvPython = '$backendDir/.venv/Scripts/python.exe';
        if (await File(venvPython).exists()) {
          pythonPath = venvPython;
        } else {
          pythonPath = 'python';
        }
      }

      // 2. Launch the server directly
      debugPrint('BackendManager: Launching server via $pythonPath...');
      
      final List<String> args = useUv 
          ? ['run', 'python', '-m', 'app.main'] 
          : ['-m', 'app.main'];

      _backendProcess = await Process.start(
        pythonPath!,
        args,
        workingDirectory: backendDir,
        runInShell: true,
        mode: ProcessStartMode.detachedWithStdio,
      );

      // Log capture for debugging
      _backendProcess?.stdout.transform(const SystemEncoding().decoder).listen((data) {
        debugPrint('Backend stdout: ${data.trim()}');
      });
      _backendProcess?.stderr.transform(const SystemEncoding().decoder).listen((data) {
        debugPrint('Backend stderr: ${data.trim()}');
      });

      debugPrint('BackendManager: Backend process reached detached state.');
    } catch (e) {
      debugPrint('BackendManager Error: $e');
    }
  }

  void dispose() {
    _backendProcess?.kill();
  }
}
