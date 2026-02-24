import 'package:flutter/material.dart';
import 'package:vitaguard_app/facility/main_facility.dart';
import 'package:vitaguard_app/auth/ui/screens/create_account_screen.dart';
import 'package:vitaguard_app/auth/ui/widgets/image_of_the_record.dart';

class FacilityRegisterScreen extends StatefulWidget {
  const FacilityRegisterScreen({super.key});

  @override
  State<FacilityRegisterScreen> createState() => _FacilityRegisterScreenState();
}

class _FacilityRegisterScreenState extends State<FacilityRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _typeController = TextEditingController();
  final _attachimageController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return CreateAccountScreen(
      title: "Create Facility Account",
      buttonText: "Sign up",
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
          'hint': 'Attach image of the record',
          'controller': _attachimageController,
          'type': FieldType.navigation,
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ImageOfTheRecord()),
            );
          },
        },
      ],
      onSubmit: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainFacility(name: _nameController.text),
          ),
        );
      },
    );
  }
}



