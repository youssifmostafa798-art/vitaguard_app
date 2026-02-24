import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vitaguard_app/auth/ui/auth_provider.dart';
import 'package:vitaguard_app/auth/ui/screens/create_account_screen.dart';
import 'package:vitaguard_app/auth/ui/widgets/patients_medical_history.dart';

class PatientRegisterScreen extends StatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  State<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends State<PatientRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _genderController = TextEditingController();
  final _medicalHistoryController = TextEditingController();

  void _handleSignUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.registerPatient(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please sign in.'),
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Registration failed')),
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
          'hint':
              'Age', // Note: Age is not in current backend schema, but we'll keep it in UI
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
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MedicalHistoryScreen()),
            );
          },
        },
      ],
      onSubmit: _handleSignUp,
    );
  }
}
