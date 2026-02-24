import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/auth/ui/screens/sign_in_screen.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/components/custom_logo.dart';

enum FieldType { normal, password, navigation, gender }

class CreateAccountScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> fields;
  final String buttonText;
  final VoidCallback onSubmit;

  const CreateAccountScreen({
    super.key,
    required this.title,
    required this.fields,
    required this.buttonText,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VitaGuardLogo(size: 20),
                Gap(10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff003F6B),
                  ),
                ),

                Gap(20),

                /// Fields
                ...fields.map((field) {
                  final FieldType type = field['type'];

                  if (type == FieldType.gender) {
                    return _buildGenderField(field);
                  }

                  return _buildTextField(field, type);
                }),

                const Gap(18),

                /// Submit Button
                Button(title: buttonText, onTap: onSubmit),

                const Gap(10),

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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                borderRadius: BorderRadius.circular(25),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          hintText: field['hint'],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
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
        return const Icon(Icons.arrow_forward_ios, size: 16);
      default:
        return null;
    }
  }
}



