import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/compenets/custem_background.dart';
import 'package:vitaguard_app/compenets/custem_text.dart';
import 'package:vitaguard_app/core/simple_header.dart';

class Alarts extends StatelessWidget {
  const Alarts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(title: "Alarts"),

      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(10),

                const Gap(30),

                ///  Result Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xff003F6B),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ///  Bullet 1
                      CustemText(
                        text:
                            "• The patient’s last medication was taken today at 9:00 AM"
                            "• Please measure blood pressure tomorrow before the visit",
                        size: 15,
                        color: Colors.black,
                        height: 1.5,
                      ),
                      Gap(20),

                      ///  Bullet 2
                      CustemText(
                        text:
                            "• Dr. Ahmed’s appointment at 3:00 PM – Room 12"
                            "• Blood test for the patient tomorrow at 10:00 AM",
                        size: 15,
                        color: Colors.black,
                        height: 1.5,
                      ),

                      Gap(20),

                      ///  Bullet 3
                      CustemText(
                        text:
                            "• New lab result is ready – please see the doctor"
                            "• Change in patient’s condition – contact the doctor immediately",
                        size: 15,
                        color: Colors.black,
                        height: 1.5,
                      ),
                    ],
                  ),
                ),

                const Gap(40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
