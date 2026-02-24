import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_text.dart';

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
      padding: EdgeInsets.all(20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Color(0xff003F6B)),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: const Color(0xff003F6B)),
              Gap(10),
              CustemText(
                text: title,
                weight: FontWeight.bold,
                size: 12,
                color: Color(0xff003F6B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



