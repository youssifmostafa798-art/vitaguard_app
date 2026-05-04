import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/data/models/patient/patient_models.dart';

import '../../../core/utils/custem_background.dart';
import '../../../core/utils/custem_bottom.dart';
import '../../../core/utils/custem_text.dart';

class RadiologyResult extends StatelessWidget {
  final XRayResult result;

  const RadiologyResult({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final bool isInfected = result.prediction == 'PNEUMONIA';
    final String confidenceText = result.confidence != null
        ? "${(result.confidence! * 100).clamp(0, 100).toStringAsFixed(1)}%"
        : "N/A";

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(
        title: "Radiology Result",
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Gap(30.h),

                /// Status Header
                CustemText(
                  text: result.isValid ? "Analysis Complete" : "Invalid Scan",
                  size: 22,
                  weight: FontWeight.bold,
                  color: const Color(0xff003F6B),
                ),
                Gap(20.h),

                /// Results Container
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: const Color(0xff003F6B),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustemText(
                        text: result.isValid
                            ? "Result: ${isInfected ? 'INFECTED' : 'NORMAL'}"
                            : "Result: UNREADABLE",
                        size: 18,
                        weight: FontWeight.bold,
                        color: result.isValid
                            ? (isInfected ? Colors.red : Colors.green)
                            : Colors.orange,
                      ),
                      Gap(15.h),

                      if (result.isValid) ...[
                        CustemText(
                          text: "Confidence: $confidenceText",
                          size: 16,
                          color: Colors.black87,
                        ),
                        Gap(15.h),
                      ],

                      CustemText(
                        text:
                            result.reportText ??
                            (result.isValid
                                ? "The AI analysis suggests ${isInfected ? 'findings consistent with pneumonia' : 'normal lung patterns'}. Please consult a physician for a formal diagnosis."
                                : "The uploaded image does not appear to be a valid chest X-ray. Please ensure you are uploading a clear frontal chest radiograph."),
                        size: 15,
                        color: Colors.black,
                        height: 1.5,
                      ),

                      Gap(20.h),
                    ],
                  ),
                ),
                const Spacer(),
                Button(
                  title: "Dismiss",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                Gap(40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
