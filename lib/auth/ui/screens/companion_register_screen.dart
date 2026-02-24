import 'package:flutter/material.dart';
import 'package:vitaguard_app/companion/main_companion.dart';
import 'package:vitaguard_app/auth/ui/widgets/auth_textfield.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/components/custom_logo.dart';

class CompanionRegisterScreen extends StatefulWidget {
  const CompanionRegisterScreen({super.key});

  @override
  State<CompanionRegisterScreen> createState() =>
      _CompanionRegisterScreenState();
}

class _CompanionRegisterScreenState extends State<CompanionRegisterScreen> {
  final codeCtrl = TextEditingController();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: AppBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      VitaGuardLogo(),

                      const SizedBox(height: 40),

                      CustemText(
                        text: "Create your Code",
                        color: const Color(0xff003F6B),
                        size: 22,
                        weight: FontWeight.bold,
                      ),
                      const SizedBox(height: 20),

                      AuthTextField(
                        hint: "User Name",
                        controller: _nameController,
                      ),

                      const SizedBox(height: 20),

                      AuthTextField(hint: "Enter Code", controller: codeCtrl),

                      const SizedBox(height: 50),

                      Button(
                        title: "Sign In",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MainCompanion(name: _nameController.text),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),
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



