import 'package:flutter/material.dart';
import 'package:vitaguard_app/compenets/custem_text.dart';

class SimpleButtom extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const SimpleButtom({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xff003F6B),
            borderRadius: BorderRadius.circular(25),
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
