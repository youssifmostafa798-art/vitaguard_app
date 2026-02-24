import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/components/custom_logo.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';

class ImageOfTheRecord extends StatelessWidget {
  const ImageOfTheRecord({super.key});

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
                Gap(50),

                //import Upload image wedget (ui)
                CustemText(
                  text: "Upload image",
                  size: 18,
                  color: Color(0xff003F6B),
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
}



