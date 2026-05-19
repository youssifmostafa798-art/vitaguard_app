import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class ClinicalCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final IconData? icon;
  final Color? iconColor;

  const ClinicalCard({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 600.w), // Ensures readability (~70-80 characters wide)
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      margin: EdgeInsets.only(top: 4.h, bottom: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor, size: 20.r),
            Gap(12.w),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final Widget child;
  const AlertCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClinicalCard(
      backgroundColor: const Color(0xFFFFF1F1),
      borderColor: const Color(0xFFFFC2C2),
      icon: Icons.warning_rounded,
      iconColor: const Color(0xFFC62828),
      child: child,
    );
  }
}

class WarningCard extends StatelessWidget {
  final Widget child;
  const WarningCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClinicalCard(
      backgroundColor: const Color(0xFFFFF8E1),
      borderColor: const Color(0xFFFFE082),
      icon: Icons.info_outline_rounded,
      iconColor: const Color(0xFFF57F17),
      child: child,
    );
  }
}

class InfoCard extends StatelessWidget {
  final Widget child;
  const InfoCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClinicalCard(
      backgroundColor: const Color(0xFFE3EEF7),
      borderColor: const Color(0xFFB9D5EE),
      icon: Icons.lightbulb_outline_rounded,
      iconColor: const Color(0xFF0D3B66),
      child: child,
    );
  }
}
