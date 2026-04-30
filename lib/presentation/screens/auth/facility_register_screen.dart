import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitaguard_app/presentation/screens/auth/create_account_screen.dart';
import 'package:vitaguard_app/presentation/widgets/auth/image_of_the_record.dart';
import 'package:vitaguard_app/presentation/widgets/auth/signup_success_dialog.dart';
import 'package:vitaguard_app/presentation/controllers/auth/auth_provider.dart';

class FacilityRegisterScreen extends ConsumerStatefulWidget {
  const FacilityRegisterScreen({super.key});

  @override
  ConsumerState<FacilityRegisterScreen> createState() =>
      _FacilityRegisterScreenState();
}

class _FacilityRegisterScreenState
    extends ConsumerState<FacilityRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _typeController = TextEditingController();
  final _attachimageController = TextEditingController();
  File? _selectedRecordImage;
  String? _localError;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    return CreateAccountScreen(
      title: "Create Facility Account",
      buttonText: "Sign up",
      errorMessage: _localError ?? authState.error?.toString(),
      fields: [
        {
          'hint': 'Name of Facility',
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
          'hint': 'Address',
          'controller': _addressController,
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
          'hint': 'Type of facility',
          'controller': _typeController,
          'type': FieldType.normal,
        },
        {
          'hint': _selectedRecordImage != null
              ? 'Image Selected'
              : 'Attach image of the record',
          'controller': _attachimageController,
          'type': FieldType.navigation,
          'onTap': () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ImageOfTheRecord(initialImage: _selectedRecordImage),
              ),
            );
            if (result != null && result is File) {
              setState(() {
                _selectedRecordImage = result;
                _attachimageController.text = result.path.split('/').last;
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
            _addressController.text.isEmpty ||
            _typeController.text.isEmpty) {
          setState(() => _localError = 'Please fill all required fields');
          return;
        }

        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() => _localError = 'Passwords do not match');
          return;
        }

        final authController = ref.read(authControllerProvider.notifier);
        final success = await authController.registerFacility(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          facilityType: _typeController.text.trim(),
          recordImage: _selectedRecordImage,
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