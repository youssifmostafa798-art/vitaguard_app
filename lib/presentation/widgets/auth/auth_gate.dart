import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitaguard_app/presentation/controllers/auth/auth_provider.dart';
import 'package:vitaguard_app/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:vitaguard_app/presentation/screens/splash_screen.dart';
import 'package:vitaguard_app/features/patient/main_patient.dart';
import 'package:vitaguard_app/features/doctor/main_doctor.dart';
import 'package:vitaguard_app/features/companion/main_companion.dart';
import 'package:vitaguard_app/features/facility/main_facility.dart';

/// AuthGate widget that handles authentication state and routes to the appropriate screen.
/// This replaces the timer-based navigation in SplashScreen with reactive auth state.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    debugPrint('[STATE] AuthGate rebuild: $authState');

    return authState.when(
      data: (userData) {
        // If userData is null, user is not authenticated
        if (userData == null) {
          debugPrint('[AUTH] No user data - showing onboarding/login');
          return const OnboardingScreen();
        }

        // User is authenticated - route based on role
        final role = userData['role'] as String?;
        final name = userData['name'] as String? ?? 'User';

        debugPrint('[AUTH] User authenticated with role: $role');

        switch (role) {
          case 'doctor':
            return MainDoctor(name: name);
          case 'companion':
            return MainCompanion(name: name);
          case 'facility':
            return MainFacility(name: name);
          default:
            return MainPatient(name: name);
        }
      },
      loading: () {
        debugPrint('[AUTH] Auth state loading - showing splash');
        return const SplashScreen();
      },
      error: (error, stackTrace) {
        debugPrint('[ERROR] Auth state error: $error');
        // On error, show error screen with retry option
        return _AuthErrorScreen(
          error: error,
          onRetry: () {
            // Invalidate the provider to trigger a retry
            ref.invalidate(authControllerProvider);
          },
        );
      },
    );
  }
}

/// Error screen shown when auth initialization fails.
class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'Authentication Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Navigate to onboarding as fallback
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
