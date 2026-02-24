import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/auth/ui/widgets/consultation_options_screen.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/components/custom_logo.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';

class ProfessionalId extends StatelessWidget {
  const ProfessionalId({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                VitaGuardLogo(size: 20),
                Gap(20),

                const Gap(16),
                //import x ray wedget (ui)
                CustemText(
                  text: "Upload Professional Association ID card.",
                  color: Color(0xff003F6B),
                  size: 18,
                  weight: FontWeight.bold,
                ),
                Gap(10),
                TextField(
                  readOnly: true,
                  maxLines: 5,
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.image_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),

                Spacer(),

                Button(
                  title: "Confirm",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConsultationOptionsScreen(),
                      ),
                    );
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



