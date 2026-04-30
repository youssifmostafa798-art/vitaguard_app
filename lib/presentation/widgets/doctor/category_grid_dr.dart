import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/features/doctor/data/home_categories_doctor.dart';
import 'package:vitaguard_app/presentation/widgets/custem_text.dart';
import 'package:vitaguard_app/presentation/widgets/patient/category_item.dart';

class CategoryGridDr extends StatelessWidget {
  final String drName;

  const CategoryGridDr({super.key, required this.drName});

  @override
  Widget build(BuildContext context) {
    final categories = homeCategoriesDr(context, drName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Gap(20.h),

        /// Title
        CustemText(
          text: "Categories",
          size: 25,
          spacing: 3,
          color: Color(0xff003F6B),
          weight: FontWeight.bold,
        ),

        Gap(15.h),

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