import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/presentation/screens/auth/sign_in_screen.dart';

Future<void> showSignupSuccessDialog(
  BuildContext context, {
  String message = "Sign up successful",
  Duration duration = const Duration(milliseconds: 1200),
}) async {
  if (!context.mounted) return;

  showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Sign up successful',
    barrierColor: Colors.black54,
    useRootNavigator: true,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 260),
            tween: Tween<double>(begin: 0.9, end: 1.0),
            builder: (context, scale, child) {
              return Opacity(
                opacity: animation.value,
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: Container(
              width: 260.w,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFF2E7D32),
                    size: 56.r,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF003F6B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 180),
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );

  await Future<void>.delayed(duration);

  if (!context.mounted) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.pop();
  }

  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => SignInScreen()),
    (route) => false,
  );
}
