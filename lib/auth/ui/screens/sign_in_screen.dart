import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitaguard_app/auth/ui/widgets/auth_textfield.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/components/custom_logo.dart';
import 'package:vitaguard_app/core/providers.dart';

// Import target screens
import 'package:vitaguard_app/patient/main_patient.dart';
import 'package:vitaguard_app/doctor/main_doctor.dart';
import 'package:vitaguard_app/companion/main_companion.dart';
import 'package:vitaguard_app/facility/main_facility.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool _rememberMe = false;

  // @override
  //  void dispose() {
  //   emailCtrl.dispose();
  //    passCtrl.dispose();
  //   super.dispose();
  //}
  //--------------------------------
  //delete after end the app
  // patient email (eng210091@nilehi.edu.eg) -  pass (123456789)
  // facility email (youssifkenk) - pass (123456789)
  // Dr email (youssifmostafa798) pass (1234567890)
  @override
  void initState() {
    emailCtrl.text = 'youssifmostafa798@gmail.com';
    passCtrl.text = '1234567890';
    super.initState();
  }

  //-------------------------------
  void _handleSignIn() async {
    final auth = ref.read(authProvider);
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your credentials")),
      );
      return;
    }

    final success = await auth.login(email, password);

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);

      final role = await auth.getUserRole();
      if (!mounted) return;

      Widget nextScreen;
      final name = auth.userName;

      switch (role) {
        case 'doctor':
          nextScreen = MainDoctor(name: name);
          break;
        case 'companion':
          nextScreen = MainCompanion(name: name);
          break;
        case 'facility':
          nextScreen = MainFacility(name: name);
          break;
        default:
          nextScreen = MainPatient(name: name);
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.error ?? 'Login failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: AppBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const VitaGuardLogo(),
                      SizedBox(height: 20.h),
                      AuthTextField(hint: "Email", controller: emailCtrl),
                      SizedBox(height: 20.h),
                      AuthTextField(
                        hint: "Password",
                        controller: passCtrl,
                        obscure: true,
                        suffixIcon: const Icon(Icons.visibility),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                                child: Icon(
                                  _rememberMe
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: const Color(0xff0D3B66),
                                  size:
                                      24.r, // using screenutils radius scaling
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "Remember me",
                                style: TextStyle(
                                  color: const Color(0xff0D3B66),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Forget password?",
                              style: TextStyle(
                                color: const Color(0xff0D3B66),
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      if (isLoading)
                        const CircularProgressIndicator()
                      else
                        Button(
                          title: "Sign In",
                          onTap: () {
                            debugPrint('Sign In Button Clicked');
                            _handleSignIn();
                          },
                        ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Need an account? Sign Up"),
                      ),
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
