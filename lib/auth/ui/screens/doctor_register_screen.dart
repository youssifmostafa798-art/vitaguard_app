import 'package:flutter/material.dart';
import 'package:vitaguard_app/doctor/main_doctor.dart';
import 'package:vitaguard_app/auth/ui/screens/create_account_screen.dart';
import 'package:vitaguard_app/auth/ui/widgets/professional_id.dart';

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
          'hint': 'Professional Association ID',
          'controller': _professionalIdController,
          'type': FieldType.navigation,
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfessionalId()),
            );
          },
        },
      ],
      onSubmit: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainDoctor(name: _nameController.text),
          ),
        );
      },
    );
  }
}



