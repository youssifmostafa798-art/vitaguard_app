import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vitaguard_app/companion/data/companion_models.dart';
import 'package:vitaguard_app/companion/home/screens/alarts.dart';
import 'package:vitaguard_app/models/category_model.dart';
import 'package:vitaguard_app/patient/home/screen/daily_report.dart';
import 'package:vitaguard_app/patient/home/screen/medical_history_screen.dart';

List<CategoryModel> homeCategoriesCompanion(
  BuildContext context,
  {
  LinkedPatientStatus? patientStatus,
}) {
  return [
    CategoryModel(
      icon: LucideIcons.fileClock,
      title: "Medical history",
      onTap: () {
        if (patientStatus == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link a patient account before opening medical history.'),
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicalHistoryScreen.forCompanion(
              patientName: patientStatus.name,
              patientId: patientStatus.patientId,
            ),
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
      icon: LucideIcons.bellRing,
      title: "Alert",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Alarts()),
        );
      },
    ),
  ];
}
