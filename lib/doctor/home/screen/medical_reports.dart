import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MedicalReports extends StatelessWidget {
  const MedicalReports({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(
        title: "Medical Reports",
        automaticallyImplyLeading: true,
      ),
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
                      Gap(20.h),

                      ///  Upload Container
                      Container(
                        width: double.infinity,
                        height: 300.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: const Color(0xff003F6B),
                            width: 1.2.w,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 60.r,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                      Gap(50.h),

                      ///  Confirm Button
                      Button(
                        title: 'Confirm',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      Gap(20.h),
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
