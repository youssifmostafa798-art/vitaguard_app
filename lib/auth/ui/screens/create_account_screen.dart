import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/auth/ui/screens/sign_in_screen.dart';
import 'package:vitaguard_app/auth/ui/widgets/auth_error_banner.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';

enum FieldType { normal, password, navigation, gender }

class CreateAccountScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> fields;
  final String buttonText;
  final VoidCallback onSubmit;
  final String? errorMessage;

  const CreateAccountScreen({
    super.key,
    required this.title,
    required this.fields,
    required this.buttonText,
    required this.onSubmit,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null && errorMessage!.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: AppBackground(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 25.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Gap(20.h),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff003F6B),
                  ),
                ),

                Gap(20.h),

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
                          key: ValueKey(errorMessage),
                          message: errorMessage!,
                        )
                      : const SizedBox.shrink(),
                ),

                if (hasError) Gap(12.h),

                /// Fields
                ...fields.map((field) {
                  final FieldType type = field['type'];

                  if (type == FieldType.gender) {
                    return _buildGenderField(field);
                  }

                  return _buildTextField(field, type);
                }),

                Gap(18.h),

                /// Submit Button
                Button(title: buttonText, onTap: onSubmit),

                Gap(10.h),

                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SignInScreen()),
                  ),
                  child: const Text("Already have an account? Sign in"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= TEXT FIELD =================
  Widget _buildTextField(Map<String, dynamic> field, FieldType type) {
    final VoidCallback? onTap = field['onTap'];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: GestureDetector(
        onTap: type == FieldType.navigation ? onTap : null,
        child: AbsorbPointer(
          absorbing: type == FieldType.navigation,
          child: TextField(
            controller: field['controller'],
            obscureText: type == FieldType.password,
            readOnly: type == FieldType.navigation,
            keyboardType: field['keyboardType'] ?? TextInputType.text,
            maxLines: field['maxLines'] ?? 1,
            decoration: InputDecoration(
              hintText: field['hint'],
              suffixIcon: _buildSuffixIcon(type),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= GENDER FIELD =================
  Widget _buildGenderField(Map<String, dynamic> field) {
    final controller = field['controller'] as TextEditingController;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: DropdownButtonFormField<String>(
        initialValue: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          hintText: field['hint'],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.r)),
        ),
        items: const [
          DropdownMenuItem(value: 'male', child: Text('Male')),
          DropdownMenuItem(value: 'female', child: Text('Female')),
        ],
        onChanged: (value) {
          controller.text = value!;
        },
      ),
    );
  }

  // ================= SUFFIX ICON =================
  Widget? _buildSuffixIcon(FieldType type) {
    switch (type) {
      case FieldType.password:
        return const Icon(Icons.visibility_off);
      case FieldType.navigation:
        return Icon(Icons.arrow_forward_ios, size: 16.r);
      default:
        return null;
    }
  }
}
