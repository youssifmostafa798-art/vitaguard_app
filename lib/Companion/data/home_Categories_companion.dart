import 'package:flutter/material.dart';
import 'package:vitaguard_app/Companion/Home/screens/alarts.dart';
import 'package:vitaguard_app/Models/category_model.dart';
import 'package:vitaguard_app/patient/Home/screen/daily_report.dart';
import 'package:vitaguard_app/patient/Home/screen/medical_history_update.dart';

List<CategoryModel> homeCategoriesCompanion(
  BuildContext context,
  String companionName,
) {
  return [
    CategoryModel(
      icon: Icons.medical_information,
      title: "Medical history",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicalHistoryUpdate(firstNamee: companionName),
          ),
        );
      },
    ),
    CategoryModel(
      icon: Icons.description,
      title: "Daily Report",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailyReport()),
        );
      },
    ),
    CategoryModel(
      icon: Icons.add_alert,
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
