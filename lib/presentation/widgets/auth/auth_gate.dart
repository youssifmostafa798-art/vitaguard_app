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
        // On error, show onboarding so user can try again
        return const OnboardingScreen();
      },
    );
  }
}
