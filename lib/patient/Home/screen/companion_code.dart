import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/compenets/custem_background.dart';
import 'package:vitaguard_app/compenets/custem_text.dart';
import 'package:vitaguard_app/core/simple_buttom.dart';
import 'package:vitaguard_app/core/simple_header.dart';

class CompanionCode extends StatelessWidget {
  final String code;
  final VoidCallback? onBack;
  final VoidCallback? onChangeCode;

  const CompanionCode({
    super.key,
    required this.code,
    this.onBack,
    this.onChangeCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeader(title: "Companion Code"),
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(10),

                Gap(40),

                ///  Code Label
                CustemText(
                  text: "Code",
                  size: 18,
                  color: Color(0xff0E3C63),
                  weight: FontWeight.bold,
                ),

                Gap(10),

                ///  Code Field (Read Only)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: const Color(0xff0E3C63)),
                  ),
                  child: CustemText(
                    text: code,
                    size: 16,
                    color: Colors.black,
                    weight: FontWeight.w600,
                  ),
                ),

                Gap(30),

                ///  Change Code Button
                SimpleButtom(
                  text: "Change Code",
                  onTap: () {
                    Navigator.pop(context);
                    print("Change Code");
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
