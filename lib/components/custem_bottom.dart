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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 65,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xff003F6B),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Gap(10),
              CustemText(
                //font
                text: title.toUpperCase(),
                size: 25,
                weight: FontWeight.bold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



