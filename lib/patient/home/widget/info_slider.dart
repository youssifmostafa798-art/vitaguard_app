import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class InfoSlider extends StatelessWidget {
  final List<String> images;

  const InfoSlider({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => Gap(15.w),
        itemBuilder: (context, index) {
          return Container(
            width: 300.w,

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.r),
            ),
            clipBehavior: Clip.hardEdge,
            child: Image.asset(height: 120.h, images[index], fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}
