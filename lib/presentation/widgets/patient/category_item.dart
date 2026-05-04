import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../core/utils/custem_text.dart';

class CategoryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const CategoryItem({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.r),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.r),
            border: Border.all(color: const Color(0xff003F6B)),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 45.r, color: const Color(0xff003F6B)),
              Gap(10.h),
              CustemText(
                text: title,
                weight: FontWeight.bold,
                size: 10,
                color: const Color(0xff003F6B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
