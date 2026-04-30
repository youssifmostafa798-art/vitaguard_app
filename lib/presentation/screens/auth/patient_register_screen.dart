import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitaguard_app/presentation/screens/auth/create_account_screen.dart';
import 'package:vitaguard_app/presentation/widgets/auth/signup_success_dialog.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/data/models/patient/patient_models.dart';
import 'package:vitaguard_app/data/repositories/patient/patient_repository.dart';
import 'package:vitaguard_app/presentation/screens/patient/medical_history_screen.dart';
import 'package:vitaguard_app/presentation/controllers/auth/auth_provider.dart';

class PatientRegisterScreen extends ConsumerStatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  ConsumerState<PatientRegisterScreen> createState() =>
      _PatientRegisterScreenState();
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
  String? _localError;

  void _handleSignUp() async {
    if (_localError != null) {
      setState(() => _localError = null);
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _localError = 'Passwords do not match');
      return;
    }

    final auth = ref.read(authControllerProvider.notifier);
    final success = await auth.registerPatient(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phone: _phoneController.text.trim(),
      gender: _genderController.text.trim(),
      age: _ageController.text.trim(),
    );

    if (success) {
      if (_draftHistory != null && await ref.read(authControllerProvider.notifier).isAuthenticated()) {
        try {
          await PatientRepository().updateMedicalHistory(_draftHistory!);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Account created, but medical history could not be saved: ${ErrorMapper.map(e)}',
                ),
              ),
            );
          }
        }
      }

      if (!mounted) return;
      setState(() => _localError = null);
      await showSignupSuccessDialog(context);
    } else {
      if (!mounted) return;
      setState(() => _localError = ref.read(authControllerProvider).error?.toString() ?? 'Registration failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    return CreateAccountScreen(
      title: "Create Patient Account",
      buttonText: "sign up",
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
          'hint': 'Patient’s Medical History',
          'controller': _medicalHistoryController,
          'type': FieldType.navigation,
          'onTap': () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicalHistoryScreen.forDraft(
                  initialHistory: _draftHistory,
                ),
              ),
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