import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/presentation/widgets/custem_text.dart';

class SimpleButtom extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const SimpleButtom({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(25.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: const Color(0xff003F6B),
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: CustemText(
            text: text,
            size: 16,
            color: Colors.white,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
