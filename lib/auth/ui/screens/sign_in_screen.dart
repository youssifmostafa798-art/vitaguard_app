import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed')),
      );
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const VitaGuardLogo(),
                      const SizedBox(height: 20),
                      AuthTextField(
                        hint: "Email",
                        controller: emailCtrl,
                      ),
                      const SizedBox(height: 20),
                      AuthTextField(
                        hint: "Password",
                        controller: passCtrl,
                        obscure: true,
                        suffixIcon: const Icon(Icons.visibility),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text("Forget password?"),
                        ),
                      ),
                      const SizedBox(height: 200),
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
