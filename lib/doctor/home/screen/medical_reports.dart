import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/components/custem_field.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MedicalReports extends StatefulWidget {
  const MedicalReports({super.key});

  @override
  State<MedicalReports> createState() => _MedicalReportsState();
}

class _MedicalReportsState extends State<MedicalReports> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _drescController = TextEditingController();
  final bool _isLoading = false;
  bool _isPicking = false;
  File? _selectedFile;

  Future<void> _pickImage() async {
    if (_isPicking) return;
    try {
      _isPicking = true;
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
        });
      }
    } finally {
      _isPicking = false;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _drescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(
        title: "Medical Reports",
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: AppBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Gap(20.h),

                      ///  Upload Container
                      CustemField(
                        title: "Mobile Number",
                        hint: "Enter Patient's Phone",
                        controller: _phoneController,
                      ),

                      Gap(20.h),
                      CustemField(
                        title: "Patient's Name ",
                        hint: "Enter Patient's Name",
                        controller: _nameController,
                      ),
                      Gap(20.h),
                      CustemField(
                        title: "Drescription",
                        hint: "Enter Drescription",
                        controller: _drescController,
                      ),
                      Gap(20.h),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 180.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xff0D3B66)),
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                          child: _selectedFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(25),
                                  child: Image.file(
                                    _selectedFile!,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 50,
                                        color: Color(0xff0D3B66),
                                      ),
                                      Gap(8),
                                      Text(
                                        "Tap to select image/PDF",
                                        style: TextStyle(
                                          color: Color(0xff0D3B66),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),

                      Gap(40.h),
                      Button(
                        title: _isLoading ? "Uploading..." : "Confirm",
                        onTap: () => Navigator.pop(context),
                      ),
                      Gap(20.h),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
