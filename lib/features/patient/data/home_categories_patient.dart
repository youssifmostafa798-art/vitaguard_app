import 'package:flutter/material.dart';
import 'package:vitaguard_app/data/models/category_model.dart';
import 'package:vitaguard_app/presentation/screens/patient/companion_code.dart';
import 'package:vitaguard_app/presentation/screens/patient/daily_report.dart';
import 'package:vitaguard_app/presentation/screens/patient/guidance_videos.dart';
import 'package:vitaguard_app/presentation/screens/patient/medical_history_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

List<CategoryModel> homeCategoriesPatient(
  BuildContext context,
  String patientName,
) {
  return [
    CategoryModel(
      icon: LucideIcons.fileClock,
      title: "Medical history",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MedicalHistoryScreen.forPatient(patientName: patientName),
          ),
        );
      },
    ),
    CategoryModel(
      icon: LucideIcons.clipboardCheck,
      title: "Daily Report",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailyReportScreen()),
        );
      },
    ),
    CategoryModel(
      icon: LucideIcons.playCircle,
      title: "Guidance videos",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GuidanceVideos()),
        );
      },
    ),
    CategoryModel(
      icon: LucideIcons.qrCode,
      title: "Companion Code",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const CompanionCode(key: ValueKey('companionCodeScreen')),
          ),
        );
      },
    ),
  ];
}
