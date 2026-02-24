import 'package:flutter/material.dart';
import 'package:vitaguard_app/doctor/home/screen/daily_reports.dart';
import 'package:vitaguard_app/doctor/home/screen/medical_reports.dart';
import 'package:vitaguard_app/models/category_model.dart';

List<CategoryModel> homeCategoriesDr(BuildContext context, String drName) {
  return [
    CategoryModel(
      icon: Icons.description,
      title: "Medical Reports",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MedicalReports()),
        );
      },
    ),
    CategoryModel(
      icon: Icons.today,
      title: "Daily Reports",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DailyReports()),
        );
      },
    ),
    CategoryModel(
      icon: Icons.medical_information,
      title: "Labs",
      onTap: () {
        print("Soon");
      },
    ),
  ];
}
