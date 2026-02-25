//buttom
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:vitaguard_app/components/custem_text.dart';

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
        borderRadius: BorderRadius.circular(40),
        child: Ink(
          width: double.infinity,
          height: 65,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xff003F6B),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Gap(10),
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
