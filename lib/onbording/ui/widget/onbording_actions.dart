//actions
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/auth/ui/screens/role_screen.dart';

class OnboardingActions extends StatelessWidget {
  final PageController controller;
  final bool isLast;

  const OnboardingActions({
    super.key,
    required this.controller,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Button(
        onTap: () {
          if (isLast) {
            // Navigate to create accounte
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RoleScreen()),
            );
          } else if (isLast == false) {
            controller.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            RoleScreen();
          }
        },
        title: isLast ? 'START' : 'NEXT',
      ),
    );
  }
}
