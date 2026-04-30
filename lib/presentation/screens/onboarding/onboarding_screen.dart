import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/presentation/widgets/custem_background.dart';
import 'package:vitaguard_app/features/onboarding/model/onboarding_data.dart';
import 'package:vitaguard_app/presentation/widgets/onboarding/onboarding_page.dart';
import 'package:vitaguard_app/presentation/widgets/onboarding/onbording_actions.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppBackground(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: onboardingList.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = onboardingList[index];
                    return OnboardingPage(model: item);
                  },
                ),
              ),

              OnboardingActions(
                controller: _controller,
                isLast: onboardingList[currentIndex].isLast,
              ),
              SizedBox(height: 50.h),
            ],
          ),
        ),
      ),
    );
  }
}
