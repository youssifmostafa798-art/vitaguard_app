import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitaguard_app/presentation/screens/auth/create_account_screen.dart';
import 'package:vitaguard_app/presentation/widgets/auth/professional_id.dart';
import 'package:vitaguard_app/presentation/widgets/auth/signup_success_dialog.dart';
import 'package:vitaguard_app/presentation/controllers/auth/auth_provider.dart';

class DoctorRegisterScreen extends ConsumerStatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  ConsumerState<DoctorRegisterScreen> createState() =>
      _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends ConsumerState<DoctorRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _genderController = TextEditingController();
  final _professionalIdController = TextEditingController();
  File? _selectedIdCardImage;
  String? _localError;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    return CreateAccountScreen(
      title: "Create Doctor Account",
      buttonText: "Sign up",
      errorMessage: _localError ?? ref.read(authControllerProvider).error?.toString(),
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
          'hint': _selectedIdCardImage != null
              ? 'ID Card Selected'
              : 'Professional Association ID',
          'controller': _professionalIdController,
          'type': FieldType.navigation,
          'onTap': () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProfessionalId(initialImage: _selectedIdCardImage),
              ),
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
        if (_localError != null) {
          setState(() => _localError = null);
        }

        if (_nameController.text.isEmpty ||
            _emailController.text.isEmpty ||
            _passwordController.text.isEmpty ||
            _professionalIdController.text.isEmpty) {
          setState(() => _localError = 'Please fill all required fields');
          return;
        }

        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() => _localError = 'Passwords do not match');
          return;
        }

        final authController = ref.read(authControllerProvider.notifier);
        final success = await authController.registerDoctor(
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
          setState(() => _localError = null);
          await showSignupSuccessDialog(context);
        } else {
          if (!context.mounted) return;
          setState(
            () => _localError = ref.read(authControllerProvider).error?.toString() ?? 'Registration failed',
          );
        }
      },
    );
  }
}