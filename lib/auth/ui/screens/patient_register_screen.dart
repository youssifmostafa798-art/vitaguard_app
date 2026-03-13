import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitaguard_app/auth/ui/screens/create_account_screen.dart';
import 'package:vitaguard_app/auth/ui/widgets/patients_medical_history.dart';
import 'package:vitaguard_app/auth/ui/widgets/signup_success_dialog.dart';
import 'package:vitaguard_app/core/providers.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';
import 'package:vitaguard_app/patient/data/patient_repository.dart';

class PatientRegisterScreen extends ConsumerStatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  ConsumerState<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends ConsumerState<PatientRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _genderController = TextEditingController();
  final _medicalHistoryController = TextEditingController();

  MedicalHistory? _draftHistory;

  void _handleSignUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    final auth = ref.read(authProvider);
    final success = await auth.registerPatient(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phone: _phoneController.text.trim(),
      gender: _genderController.text.trim(),
      age: _ageController.text.trim(),
    );

    if (success) {
      if (_draftHistory != null) {
        try {
          await PatientRepository().updateMedicalHistory(_draftHistory!);
        } catch (_) {
          // ignore draft history failures
        }
      }

      if (!mounted) return;
      await showSignupSuccessDialog(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CreateAccountScreen(
      title: "Create Patient Account",
      buttonText: "sign up",
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
          'hint': 'Patient’s Medical History',
          'controller': _medicalHistoryController,
          'type': FieldType.navigation,
          'onTap': () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MedicalHistoryScreen()),
            );
            if (result is MedicalHistory) {
              setState(() {
                _draftHistory = result;
                _medicalHistoryController.text = 'Saved';
              });
            }
          },
        },
      ],
      onSubmit: _handleSignUp,
    );
  }
}
