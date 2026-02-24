import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vitaguard_app/auth/ui/auth_provider.dart';
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
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

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
                        title: isLoading ? "Processing..." : "Sign Up",
                        onTap: isLoading
                            ? null
                            : () async {
                                if (_nameController.text.isEmpty ||
                                    codeCtrl.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Please fill all fields"),
                                    ),
                                  );
                                  return;
                                }

                                final success = await authProvider
                                    .registerCompanion(
                                      name: _nameController.text.trim(),
                                      companionCode: codeCtrl.text.trim(),
                                    );

                                if (success) {
                                  if (!mounted) return;
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MainCompanion(
                                        name: authProvider.userName,
                                      ),
                                    ),
                                    (route) => false,
                                  );
                                } else {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        authProvider.error ??
                                            "Registration failed",
                                      ),
                                    ),
                                  );
                                }
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
