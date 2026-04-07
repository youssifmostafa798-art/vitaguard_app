import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeSearch extends StatelessWidget {
  final ValueChanged<String>? onChanged;

  const HomeSearch({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: const Color(0xff003F6B)),
        color: Colors.white,
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          icon: Icon(Icons.search, size: 22.r),
          hintText: "Search",
          border: InputBorder.none,
        ),
      ),
    );
  }
}
