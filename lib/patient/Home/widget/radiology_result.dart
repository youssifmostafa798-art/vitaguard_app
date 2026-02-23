import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/compenets/custem_background.dart';
import 'package:vitaguard_app/compenets/custem_bottom.dart';
import 'package:vitaguard_app/compenets/custem_text.dart';
import 'package:vitaguard_app/core/simple_header.dart';

class RadiologyResult extends StatelessWidget {
  const RadiologyResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(
        title: "Radiology Result",
        automaticallyImplyLeading: false,
      ),

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
                            "• The scan shows findings suggestive of pneumonia, "
                            "with areas of increased lung opacity.",
                        size: 15,
                        color: Colors.black,
                        height: 1.5,
                      ),
                      Gap(20),

                      ///  Bullet 2
                      CustemText(
                        text:
                            "• Clinical correlation and medical follow-up "
                            "are recommended.",
                        size: 15,
                        color: Colors.black,
                        height: 1.5,
                      ),

                      Gap(20),

                      ///  Bullet 3
                      CustemText(
                        text:
                            "• ⚠ This is a preliminary automated report and does "
                            "not replace a physician’s diagnosis.",
                        size: 15,
                        color: Colors.black,
                        height: 1.5,
                      ),
                    ],
                  ),
                ),
                Gap(200),
                Button(
                  title: "Save",
                  onTap: () {
                    Navigator.pop(context);
                  },
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
