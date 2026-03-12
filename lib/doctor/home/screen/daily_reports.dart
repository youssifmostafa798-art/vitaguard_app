import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/core/simple_header.dart';

class DailyReports extends StatelessWidget {
  const DailyReports({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const SimpleHeader(title: "Daily Reports"),
      body: SafeArea(
        child: AppBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(30),

                      /// Result Container
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
                          children: const [
                            /// Title
                            CustemText(
                              text: "Name Patient 1",
                              size: 20,
                              weight: FontWeight.w600,
                              color: Color(0xff003F6B),
                            ),
                            Gap(10),

                            /// Bullet 1
                            CustemText(
                              text:
                                  "• The patient is responding well to the prescribed medication.",
                              size: 15,
                              color: Colors.black,
                              height: 1.5,
                            ),
                            Gap(20),

                            /// Bullet 2
                            CustemText(
                              text:
                                  "• All medications were taken as scheduled with no side effects noted.",
                              size: 15,
                              color: Colors.black,
                              height: 1.5,
                            ),
                            Gap(20),

                            /// Bullet 3
                            CustemText(
                              text:
                                  "• ⚠ Treatment plan remains unchanged for today.",
                              size: 15,
                              color: Colors.black,
                              height: 1.5,
                            ),
                          ],
                        ),
                      ),

                      const Gap(300),

                      Button(
                        title: "Confirm",
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),

                      const Gap(20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}



