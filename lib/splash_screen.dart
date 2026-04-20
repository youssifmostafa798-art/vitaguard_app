import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/core/providers.dart';
import 'package:vitaguard_app/patient/main_patient.dart';
import 'package:vitaguard_app/doctor/main_doctor.dart';
import 'package:vitaguard_app/companion/main_companion.dart';
import 'package:vitaguard_app/facility/main_facility.dart';
import 'package:vitaguard_app/onbording/ui/screen/onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  bool _navigated = false;

  // Primary controller (logo + dots fade-in)
  late final AnimationController _ctrl;

  // Looping controller (dot bounce)
  late final AnimationController _dotsCtrl;

  late final List<Animation<double>> _dotBounce;

  // Loading dots entrance fade
  late final Animation<double> _dotsFade;

  @override
  void initState() {
    super.initState();

    // Total delay = animation duration (2s) + wait (1s) = 3s
    Future.delayed(const Duration(seconds: 3), _navigateToOnboarding);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Dots entrance: fade 0% → 100% between 60% and 100% of _ctrl
    _dotsFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.60, 1.0, curve: Curves.easeIn),
    );

    // Three dots with staggered bounce offsets (0, 0.33, 0.66)
    _dotBounce = List.generate(3, (i) {
      final offset = i * 0.33;
      return Tween<double>(begin: 0.0, end: -10.0).animate(
        CurvedAnimation(
          parent: _dotsCtrl,
          curve: Interval(
            offset,
            (offset + 0.40).clamp(0.0, 1.0),
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigateToOnboarding() async {
    if (_navigated || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    // Check if we have an active session
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      if (rememberMe) {
        // Auto-login bypassing the login screen
        final auth = ref.read(authProvider);
        final role = await auth.getUserRole();
        if (!mounted) return;

        Widget nextScreen;
        final name = auth.userName;

        switch (role) {
          case 'doctor':
            nextScreen = MainDoctor(name: name);
            break;
          case 'companion':
            nextScreen = MainCompanion(name: name);
            break;
          case 'facility':
            nextScreen = MainFacility(name: name);
            break;
          default:
            nextScreen = MainPatient(name: name);
        }

        _navigated = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
        return;
      } else {
        // If they did not want to be remembered, clear the session
        await Supabase.instance.client.auth.signOut();
      }
    }

    if (mounted) {
      _navigated = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E2A), // Dark blue-black
              Color(0xFF1A2A4A), // Muted navy
              Color(0xFF0B2B3B), // Deep teal
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Expanded(child: SizedBox.shrink()),
              _buildLogoWithGlow(),
              const Expanded(child: SizedBox.shrink()),
              Padding(
                padding: EdgeInsets.only(bottom: 48.h),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_ctrl, _dotsCtrl]),
                  builder: (context, _) =>
                      _buildLoadingDots(), // Fixed: rebuild every frame to ensure smooth animation updates and prevent stuttering in loading dots
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoWithGlow() {
    final logoSize = 200.r;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect
          Container(
            width: logoSize + 65,
            height: logoSize + 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.6),
                  blurRadius: 50.r,
                  spreadRadius: 15.r,
                ),
                BoxShadow(
                  color: Colors.tealAccent.withValues(alpha: 0.5),
                  blurRadius: 30.r,
                  spreadRadius: 5.r,
                ),
              ],
            ),
          ),
          // Animated Logo (Fade + Scale) – fixed: removed onPlay to prevent animation conflicts and ensure proper fade-in and scale effects
          Opacity(
            opacity: 0.6,
            child:
                Image.asset(
                      'assets/Logo/Vita Guard 2.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                    )
                    .animate()
                    .fadeIn(duration: 2.seconds, curve: Curves.easeOut)
                    .scale(
                      duration: 2.seconds,
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      curve: Curves.easeOutCubic,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Opacity(
      opacity: _dotsFade.value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return Transform.translate(
            offset: Offset(0, _dotBounce[i].value),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 5.w),
              width: 7.r,
              height: 7.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == 1
                    ? const Color(0xFF00C8FF)
                    : const Color(0xFF00C8FF).withValues(alpha: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C8FF).withValues(alpha: 0.6),
                    blurRadius: 6.r,
                    spreadRadius: 1.r,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
