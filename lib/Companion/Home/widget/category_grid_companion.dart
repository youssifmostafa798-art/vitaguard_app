import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/Companion/data/home_Categories_companion.dart';
import 'package:vitaguard_app/compenets/custem_text.dart';
import 'package:vitaguard_app/patient/Home/widget/category_item.dart';

class CategoryGridCompanion extends StatelessWidget {
  final String companionName;

  const CategoryGridCompanion({super.key, required this.companionName});
  //edit
  @override
  Widget build(BuildContext context) {
    final categories = homeCategoriesCompanion(context, companionName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// Title
        CustemText(
          text: "Categories",
          size: 25,
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
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
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
