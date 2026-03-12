import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vitaguard_app/auth/ui/auth_provider.dart';
import 'package:vitaguard_app/auth/ui/screens/create_account_screen.dart';
import 'package:vitaguard_app/auth/ui/widgets/professional_id.dart';
import 'package:vitaguard_app/auth/ui/widgets/signup_success_dialog.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _genderController = TextEditingController();
  final _professionalIdController = TextEditingController();
  File? _selectedIdCardImage;

  @override
  Widget build(BuildContext context) {
    return CreateAccountScreen(
      title: "Create Doctor Account",
      buttonText: "Sign up",
      fields: [
        {
          'hint': 'User Name',
          'controller': _nameController,
          'type': FieldType.normal,
        },
        {
          'hint': 'Email',
          'controller': _emailController,
          'type': FieldType.normal,
          'keyboardType': TextInputType.emailAddress,
        },
        {
          'hint': 'Password',
          'controller': _passwordController,
          'type': FieldType.password,
        },
        {
          'hint': 'Confirm Password',
          'controller': _confirmPasswordController,
          'type': FieldType.password,
        },
        {
          'hint': 'Age',
          'controller': _ageController,
          'type': FieldType.normal,
          'keyboardType': TextInputType.number,
        },
        {
          'hint': 'Phone Number',
          'controller': _phoneController,
          'type': FieldType.normal,
          'keyboardType': TextInputType.phone,
        },
        {
          'hint': 'Gender',
          'controller': _genderController,
          'type': FieldType.gender,
        },
        {
          'hint': _selectedIdCardImage != null ? 'ID Card Selected' : 'Professional Association ID',
          'controller': _professionalIdController,
          'type': FieldType.navigation,
          'onTap': () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfessionalId(initialImage: _selectedIdCardImage)),
            );
            if (result != null && result is File) {
              setState(() {
                _selectedIdCardImage = result;
                _professionalIdController.text = result.path.split('/').last;
              });
            }
          },
        },
      ],
      onSubmit: () async {
        if (_nameController.text.isEmpty ||
            _emailController.text.isEmpty ||
            _passwordController.text.isEmpty ||
            _professionalIdController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please fill all required fields")),
          );
          return;
        }

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.registerDoctor(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim(),
          professionalId: _professionalIdController.text.trim(),
          idCardImage: _selectedIdCardImage,
          gender: _genderController.text.trim().toLowerCase(),
          age: _ageController.text.trim(),
        );

        if (success) {
          if (!context.mounted) return;
          await showSignupSuccessDialog(context);
        } else {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? "Registration failed"),
            ),
          );
        }
      },
    );
  }
}
