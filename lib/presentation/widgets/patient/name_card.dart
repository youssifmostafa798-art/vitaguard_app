import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/utils/custem_text.dart';

class NameCard extends StatelessWidget {
  final String firstName;

  const NameCard({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustemText(text: "Name", color: Color(0xff0D3B66)),

        Gap(5),
        CustemText(
          text: firstName,
          size: 18,
          weight: FontWeight.bold,
          color: Color(0xff0D3B66),
        ),
      ],
    );
  }
}
