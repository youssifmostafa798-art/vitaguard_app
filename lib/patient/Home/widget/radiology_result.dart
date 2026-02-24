import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/compenets/custem_background.dart';
import 'package:vitaguard_app/compenets/custem_bottom.dart';
import 'package:vitaguard_app/compenets/custem_text.dart';
import 'package:vitaguard_app/core/simple_header.dart';
import '../../data/patient_models.dart';

class RadiologyResult extends StatelessWidget {
  final XRayResult result;

  const RadiologyResult({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final bool isInfected = result.prediction == 'PNEUMONIA';
    final String confidenceText = result.confidence != null
        ? "${(result.confidence! * 100).toStringAsFixed(1)}%"
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(30),

                /// Status Header
                CustemText(
                  text: result.isValid ? "Analysis Complete" : "Invalid Scan",
                  size: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff003F6B),
                ),
                const Gap(20),

                /// Results Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(20),
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
                        fontWeight: FontWeight.bold,
                        color: result.isValid
                            ? (isInfected ? Colors.red : Colors.green)
                            : Colors.orange,
                      ),
                      const Gap(15),

                      if (result.isValid) ...[
                        CustemText(
                          text: "Confidence: $confidenceText",
                          size: 16,
                          color: Colors.black87,
                        ),
                        const Gap(15),
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

                      const Gap(20),
                      CustemText(
                        text:
                            "⚠ This is a preliminary automated report and does not replace a professional medical consultation.",
                        size: 13,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
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
                const Gap(40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
