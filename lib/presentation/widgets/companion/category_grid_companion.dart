import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/features/companion/data/home_categories_companion.dart';
import 'package:vitaguard_app/presentation/widgets/custem_text.dart';
import 'package:vitaguard_app/presentation/widgets/patient/category_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitaguard_app/presentation/controllers/companion/companion_provider.dart';

class CategoryGridCompanion extends ConsumerWidget {
  const CategoryGridCompanion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companionState = ref.watch(companionControllerProvider);
    final categories = homeCategoriesCompanion(
      context,
      patientStatus: ref.read(companionControllerProvider).patientStatus,
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

        if (ref.read(companionControllerProvider).error?.toString() != null && ref.read(companionControllerProvider).patientStatus == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              ref.read(companionControllerProvider).error?.toString() ?? '',
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