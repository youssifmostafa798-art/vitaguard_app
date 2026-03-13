import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitaguard_app/onbording/ui/onbording_screen/onboarding_screen.dart';

import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'WixMadeforDisplay'),
      home: const _FirebaseBootstrapper(),
    );
  }
}

class _FirebaseBootstrapper extends StatefulWidget {
  const _FirebaseBootstrapper();

  @override
  State<_FirebaseBootstrapper> createState() => _FirebaseBootstrapperState();
}

class _FirebaseBootstrapperState extends State<_FirebaseBootstrapper> {
  late Future<FirebaseApp> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void _retry() {
    setState(() {
      _initFuture = Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _BootstrapLoading();
        }
        if (snapshot.hasError) {
          return _BootstrapError(
            error: snapshot.error,
            onRetry: _retry,
          );
        }
        return const OnboardingScreen();
      },
    );
  }
}

class _BootstrapLoading extends StatelessWidget {
  const _BootstrapLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Starting VitaGuard...'),
          ],
        ),
      ),
    );
  }
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Firebase failed to initialize.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error?.toString() ?? 'Unknown error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
