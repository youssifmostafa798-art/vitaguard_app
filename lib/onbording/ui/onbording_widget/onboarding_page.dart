import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:vitaguard_app/onbording/model/onboarding_data.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingModel model;

  const OnboardingPage({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,

      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                model.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff003F6B),
                ),
              ),
              Gap(20),
              Image.asset(model.image),
              Gap(20),
              Text(
                model.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xff003F6B),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
