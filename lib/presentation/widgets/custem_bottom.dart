import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/presentation/widgets/custem_text.dart';

//buttom

class Button extends StatelessWidget {
  const Button({super.key, required this.title, required this.onTap});

  final String title;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('Button Tapped: $title');
          if (onTap != null) onTap!();
        },
        borderRadius: BorderRadius.circular(40.r),
        child: Ink(
          width: double.infinity,
          height: 65.h,
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: const Color(0xff003F6B),
            borderRadius: BorderRadius.circular(40.r),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Gap(10.w),
                CustemText(
                  text: title.toUpperCase(),
                  size: 25,
                  weight: FontWeight.bold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}