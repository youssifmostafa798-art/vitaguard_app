import 'package:flutter/material.dart';
import 'package:vitaguard_app/models/category_model.dart';
import 'package:vitaguard_app/patient/home/screen/companion_code.dart';
import 'package:vitaguard_app/patient/home/screen/daily_report.dart';
import 'package:vitaguard_app/patient/home/screen/guidance_videos.dart';
import 'package:vitaguard_app/patient/home/screen/medical_history_update.dart';

List<CategoryModel> homeCategoriesPatient(
  BuildContext context,
  String patientName,
) {
  return [
    CategoryModel(
      icon: Icons.medical_information,
      title: "Medical history",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicalHistoryUpdate(firstNamee: patientName),
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
          MaterialPageRoute(builder: (_) => const DailyReportScreen()),
        );
      },
    ),
    CategoryModel(
      icon: Icons.video_collection,
      title: "Guidance videos",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GuidanceVideos()),
        );
      },
    ),
    CategoryModel(
      icon: Icons.qr_code,
      title: "Companion Code",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CompanionCode(),
          ),
        );
      },
    ),
  ];
}


