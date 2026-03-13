import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitaguard_app/auth/ui/widgets/auth_error_banner.dart';
import 'package:vitaguard_app/auth/ui/widgets/auth_textfield.dart';
import 'package:vitaguard_app/auth/ui/widgets/signup_success_dialog.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/components/custom_logo.dart';
import 'package:vitaguard_app/core/providers.dart';

class CompanionRegisterScreen extends ConsumerStatefulWidget {
  const CompanionRegisterScreen({super.key});

  @override
  ConsumerState<CompanionRegisterScreen> createState() =>
      _CompanionRegisterScreenState();
}

class _CompanionRegisterScreenState extends ConsumerState<CompanionRegisterScreen> {
  final codeCtrl = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    codeCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final hasError = authState.error != null && authState.error!.trim().isNotEmpty;

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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustemText(
                            text: "Enter Patient Code",
                            color: const Color(0xff003F6B),
                            size: 22,
                            weight: FontWeight.bold,
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline, color: Color(0xff003F6B)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Companion Code"),
                                  content: const Text(
                                    "To monitor a patient's health, you must enter their unique 6-digit companion code.\n\nThe patient can find this code in their profile tab.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Got it"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0, -0.08),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(position: slide, child: child),
                          );
                        },
                        child: hasError
                            ? AuthErrorBanner(
                                key: ValueKey(authState.error),
                                message: authState.error!,
                              )
                            : const SizedBox.shrink(),
                      ),

                      if (hasError) const SizedBox(height: 20),

                      AuthTextField(
                        hint: "User Name",
                        controller: _nameController,
                      ),

                      const SizedBox(height: 20),

                      AuthTextField(
                        hint: "Email",
                        controller: _emailController,
                      ),

                      const SizedBox(height: 20),

                      AuthTextField(
                        hint: "Password",
                        controller: _passwordController,
                        obscure: true,
                        suffixIcon: const Icon(Icons.visibility),
                      ),

                      const SizedBox(height: 20),

                      AuthTextField(
                        hint: "Confirm Password",
                        controller: _confirmPasswordController,
                        obscure: true,
                        suffixIcon: const Icon(Icons.visibility),
                      ),

                      const SizedBox(height: 20),

                      AuthTextField(
                        hint: "Enter 6-digit Patient Code",
                        controller: codeCtrl,
                      ),

                      const SizedBox(height: 50),

                      Button(
                        title: isLoading ? "Processing..." : "Sign Up",
                        onTap: isLoading
                            ? null
                            : () async {
                                if (_nameController.text.isEmpty ||
                                    _emailController.text.isEmpty ||
                                    _passwordController.text.isEmpty ||
                                    _confirmPasswordController.text.isEmpty ||
                                    codeCtrl.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Please fill all fields"),
                                    ),
                                  );
                                  return;
                                }

                                if (_passwordController.text !=
                                    _confirmPasswordController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Passwords do not match"),
                                    ),
                                  );
                                  return;
                                }

                                final success = await ref
                                    .read(authProvider)
                                    .registerCompanion(
                                      name: _nameController.text.trim(),
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                      companionCode: codeCtrl.text.trim(),
                                    );

                                if (!context.mounted) return;

                                if (success) {
                                  await showSignupSuccessDialog(context);
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
