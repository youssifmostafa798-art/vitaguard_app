import 'package:flutter/material.dart';

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
  });
  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final double height;
  final double spacing;
  final dynamic font;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: font,
        letterSpacing: spacing,
        fontSize: size,
        color: color,
        fontWeight: weight,

        height: height,
      ),
    );
  }
}



