import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Simplified SplashScreen that only shows branding/loading.
/// All navigation logic has been moved to AuthGate.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure logo size is responsive and fits within the screen
    final logoSize = 200.r.clamp(120.0, 0.6.sw);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                // Animated Logo with glow effect
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none, // Allow glow to breathe without clipping
                  children: [
                    // Glow effect
                    Container(
                      width: logoSize + 60.r,
                      height: logoSize + 60.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.6),
                            blurRadius: 50.r,
                            spreadRadius: 10.r,
                          ),
                          BoxShadow(
                            color: Colors.tealAccent.withValues(alpha: 0.5),
                            blurRadius: 30.r,
                            spreadRadius: 5.r,
                          ),
                        ],
                      ),
                    ),
                    // Logo
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
                  ],
                ),
                const Spacer(),
                // Loading indicator
                Padding(
                  padding: EdgeInsets.only(bottom: 48.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      return Container(
                            margin: EdgeInsets.symmetric(horizontal: 5.w),
                            width: 7.r,
                            height: 7.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == 1
                                  ? const Color(0xFF00C8FF)
                                  : const Color(
                                      0xFF00C8FF,
                                    ).withValues(alpha: 0.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00C8FF,
                                  ).withValues(alpha: 0.6),
                                  blurRadius: 6.r,
                                  spreadRadius: 1.r,
                                ),
                              ],
                            ),
                          )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .fadeIn(
                            duration: 900.ms,
                            curve: Interval(
                              i * 0.33,
                              (i * 0.33 + 0.4).clamp(0.0, 1.0),
                              curve: Curves.easeInOut,
                            ),
                          );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
