import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vitaguard_app/auth/ui/auth_provider.dart';
import 'package:vitaguard_app/auth/ui/widgets/auth_textfield.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/components/custom_logo.dart';

// Import target screens
import 'package:vitaguard_app/patient/main_patient.dart';
import 'package:vitaguard_app/doctor/main_doctor.dart';
import 'package:vitaguard_app/companion/main_companion.dart';
import 'package:vitaguard_app/facility/main_facility.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  void _handleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      emailCtrl.text.trim(),
      passCtrl.text.trim(),
    );

    if (success) {
      final role = await authProvider.getUserRole();
      if (!mounted) return;

      Widget nextScreen;
      final name = authProvider.userName;
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
        SnackBar(content: Text(authProvider.error ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

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
                      AuthTextField(hint: "Email", controller: emailCtrl),
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
                      const SizedBox(height: 20),
                      if (isLoading)
                        const CircularProgressIndicator()
                      else
                        Button(title: "Sign In", onTap: _handleSignIn),
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
