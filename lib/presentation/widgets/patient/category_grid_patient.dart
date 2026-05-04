import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/features/patient/data/home_categories_patient.dart';
import 'package:vitaguard_app/presentation/widgets/patient/category_item.dart';

import '../../../core/utils/custem_text.dart';

class CategoryGridPatient extends StatelessWidget {
  final String patientName;
  final String searchQuery;

  const CategoryGridPatient({
    super.key,
    required this.patientName,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    var categories = homeCategoriesPatient(context, patientName);

    if (searchQuery.isNotEmpty) {
      categories = categories.where((category) {
        return category.title.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// Title
        CustemText(
          text: "Categories",
          size: 22,
          spacing: 3,
          color: Color(0xff003F6B),
          weight: FontWeight.bold,
        ),

        const Gap(15),

        /// Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];

            return CategoryItem(
              icon: category.icon,
              title: category.title,
              onTap: category.onTap,
            );
          },
        ),
      ],
    );
  }
}
