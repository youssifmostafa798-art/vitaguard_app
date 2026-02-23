import 'package:flutter/material.dart';
import 'package:vitaguard_app/auth/ui/widgets/auth_textfield.dart';
import 'package:vitaguard_app/compenets/custem_background.dart';
import 'package:vitaguard_app/compenets/custem_bottom.dart';
import 'package:vitaguard_app/compenets/custom_logo.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
                      //name
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
                      //solve the screen keybord
                      const SizedBox(height: 250),
                      Button(
                        title: "Sign In",
                        onTap: () {
                          // logic
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
