import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/compenets/custem_background.dart';
import 'package:vitaguard_app/compenets/custom_logo.dart';
import 'package:vitaguard_app/compenets/custem_bottom.dart';

class MedicalHistoryScreen extends StatelessWidget {
  const MedicalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                VitaGuardLogo(size: 20),
                Gap(20),

                _box(hint: "Chronic diseases"),
                Gap(16),

                _box(hint: "Medications"),
                Gap(16),
                //import x ray wedget (ui)
                TextField(
                  readOnly: true,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "X-ray or lab tests (optional)",
                    suffixIcon: Icon(Icons.image_outlined, size: 40),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),

                Spacer(),

                Button(
                  title: "Confirm",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _box({required String hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        readOnly: true,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
        ),
      ),
    );
  }
}
