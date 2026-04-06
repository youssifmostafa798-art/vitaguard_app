import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';

class MedicalReports extends StatelessWidget {
  const MedicalReports({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(title: "", automaticallyImplyLeading: true),
      body: SafeArea(
        child: AppBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Gap(20),

                      ///  Title
                      CustemText(
                        text: "Medical Reports",
                        size: 20,
                        weight: FontWeight.w600,
                        color: Color(0xff003F6B),
                      ),

                      Gap(30),

                      ///  Upload Container
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xff003F6B),
                            width: 1.2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                      Gap(200),

                      ///  Confirm Button
                      Button(
                        title: 'Confirm',
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
