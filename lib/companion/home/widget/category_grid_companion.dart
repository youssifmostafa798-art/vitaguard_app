import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/companion/data/home_categories_companion.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/patient/home/widget/category_item.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitaguard_app/core/providers.dart';

class CategoryGridCompanion extends ConsumerWidget {
  const CategoryGridCompanion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companionState = ref.watch(companionProvider);
    final categories = homeCategoriesCompanion(
      context,
      patientStatus: companionState.patientStatus,
    );

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

        if (companionState.error != null && companionState.patientStatus == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              companionState.error!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),

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
