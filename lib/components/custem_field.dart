import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_text.dart';

class CustemField extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController? controller;
  final bool readOnly;

  const CustemField({
    super.key,
    required this.title,
    required this.hint,
    this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustemText(
          text: title,
          size: 16,
          weight: FontWeight.w600,
          color: const Color(0xff0D3B66),
        ),
        const Gap(8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xff0D3B66)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xff0D3B66), width: 3),
            ),
          ),
        ),
      ],
    );
  }
}



