import 'package:flutter/material.dart';
import 'package:vitaguard_app/auth/ui/screens/create_account_screen.dart';
import 'package:vitaguard_app/auth/ui/widgets/patient%E2%80%99s_medical_history.dart';
import 'package:vitaguard_app/patient/main_patient.dart';

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
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MedicalHistoryScreen()),
            );
          },
        },
      ],
      onSubmit: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MainPatient(name: _nameController.text),
          ),
        );
      },
    );
  }
}
