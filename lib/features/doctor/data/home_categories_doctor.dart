import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vitaguard_app/presentation/screens/doctor/daily_reports.dart';
import 'package:vitaguard_app/presentation/screens/doctor/doctor_alerts_screen.dart';
import 'package:vitaguard_app/presentation/screens/doctor/medical_reports.dart';
import 'package:vitaguard_app/data/models/category_model.dart';

List<CategoryModel> homeCategoriesDr(BuildContext context, String drName) {
  return [
    CategoryModel(
      icon: LucideIcons.bellRing,
      title: "Alerts",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DoctorAlertsScreen()),
        );
      },
    ),
    CategoryModel(
      icon: LucideIcons.fileText,
      title: "Medical Reports",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MedicalReports()),
        );
      },
    ),
    CategoryModel(
      icon: LucideIcons.clipboardCheck,
      title: "Daily Reports",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DailyReports()),
        );
      },
    ),
    CategoryModel(
      icon: LucideIcons.microscope,
      title: "Labs",
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Coming Soon")));
      },
    ),
  ];
}
