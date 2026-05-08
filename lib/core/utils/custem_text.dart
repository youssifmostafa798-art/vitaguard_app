import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustemText extends StatelessWidget {
  const CustemText({
    super.key,
    required this.text,
    this.size = 14,

    this.font = 'WixMadeforDisplay',
    this.weight = FontWeight.normal,
    this.color = Colors.white,
    this.height = 1,
    this.spacing = 1,
    this.maxline,
    this.overflow,
  });
  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final double height;
  final double spacing;
  final dynamic font;
  final int? maxline;
  final TextOverflow? overflow;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxline,
      overflow: overflow,
      style: TextStyle(
        fontFamily: font,
        letterSpacing: spacing,
        fontSize: size.sp,
        color: color,
        fontWeight: weight,

        height: height,
      ),
    );
  }
}
