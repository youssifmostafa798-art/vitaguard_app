import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/presentation/widgets/auth/auth_error_banner.dart';
import 'package:vitaguard_app/presentation/widgets/auth/auth_textfield.dart';
import 'package:vitaguard_app/presentation/widgets/auth/signup_success_dialog.dart';
import 'package:vitaguard_app/presentation/widgets/custem_background.dart';
import 'package:vitaguard_app/presentation/widgets/custem_bottom.dart';
import 'package:vitaguard_app/presentation/widgets/custem_text.dart';
import 'package:vitaguard_app/presentation/controllers/auth/auth_provider.dart';

class CompanionRegisterScreen extends ConsumerStatefulWidget {
  const CompanionRegisterScreen({super.key});

  @override
  ConsumerState<CompanionRegisterScreen> createState() =>
      _CompanionRegisterScreenState();
}

class _CompanionRegisterScreenState
    extends ConsumerState<CompanionRegisterScreen> {
  final codeCtrl = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _localError;

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
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final effectiveError = _localError ?? authState.error?.toString() ?? '';
    final hasError = effectiveError.trim().isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: AppBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      SizedBox(height: 40.h),
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
                            icon: Icon(
                              Icons.info_outline,
                              color: const Color(0xff003F6B),
                              size: 24.r,
                            ),
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
                      SizedBox(height: 20.h),
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
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                        child: hasError
                            ? AuthErrorBanner(
                                key: ValueKey(effectiveError),
                                message: effectiveError,
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (hasError) SizedBox(height: 20.h),
                      AuthTextField(
                        hint: "Your Full Name (Companion)",
                        controller: _nameController,
                      ),
                      SizedBox(height: 20.h),
                      AuthTextField(
                        hint: "Your Email Address",
                        controller: _emailController,
                      ),
                      SizedBox(height: 20.h),
                      AuthTextField(
                        hint: "Password",
                        controller: _passwordController,
                        obscure: true,
                        suffixIcon: Icon(Icons.visibility),
                      ),
                      SizedBox(height: 20.h),
                      AuthTextField(
                        hint: "Confirm Password",
                        controller: _confirmPasswordController,
                        obscure: true,
                        suffixIcon: Icon(Icons.visibility),
                      ),
                      SizedBox(height: 20.h),
                      AuthTextField(
                        hint: "Enter 6-digit Patient Code",
                        controller: codeCtrl,
                      ),
                      SizedBox(height: 50.h),
                      Button(
                        title: isLoading ? "Processing..." : "Sign Up",
                        onTap: isLoading
                            ? null
                            : () async {
                                if (_localError != null) {
                                  setState(() => _localError = null);
                                }
                                if (_nameController.text.isEmpty ||
                                    _emailController.text.isEmpty ||
                                    _passwordController.text.isEmpty ||
                                    _confirmPasswordController.text.isEmpty ||
                                    codeCtrl.text.isEmpty) {
                                  setState(
                                    () =>
                                        _localError = 'Please fill all fields',
                                  );
                                  return;
                                }

                                if (_passwordController.text !=
                                    _confirmPasswordController.text) {
                                  setState(
                                    () =>
                                        _localError = 'Passwords do not match',
                                  );
                                  return;
                                }

                                final success = await ref
                                    .read(authControllerProvider.notifier)
                                    .registerCompanion(
                                      name: _nameController.text.trim(),
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                      companionCode: codeCtrl.text.trim(),
                                    );

                                if (!context.mounted) return;

                                if (success) {
                                  await showSignupSuccessDialog(context);
                                  if (context.mounted) {
                                    setState(() => _localError = null);
                                  }
                                }
                              },
                      ),
                      SizedBox(height: 30.h),
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