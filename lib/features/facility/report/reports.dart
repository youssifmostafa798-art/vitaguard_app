import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/data/repositories/facility/facility_repository.dart';

import '../../../core/utils/custem_background.dart';
import '../../../core/utils/custem_bottom.dart';
import '../../../core/utils/custem_field.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _repository = FacilityRepository();
  bool _isLoading = false;
  bool _isPicking = false;
  File? _selectedFile;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

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

  Future<void> _uploadReport() async {
    if (_phoneController.text.trim().isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter mobile number and select a file"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _repository.uploadMedicalTest(
        patientPhone: _phoneController.text.trim(),
        testType: "Laboratory Report",
        filePath: _selectedFile!.path,
        notes: "Uploaded for ${_nameController.text.trim()}",
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report uploaded successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(
        title: "Add Report",
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: AppBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Gap(20.h),

                      CustemField(
                        title: "mobile number",
                        hint: "Enter patient's phone",
                        controller: _phoneController,
                      ),

                      Gap(20.h),

                      CustemField(
                        title: "Patient's name (optional)",
                        hint: "Enter patient's name",
                        controller: _nameController,
                      ),

                      Gap(20.h),

                      Text(
                        "Upload Report Image",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0D3B66),
                        ),
                      ),
                      Gap(10.h),

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
                        onTap: _isLoading ? null : _uploadReport,
                      ),

                      Gap(30.h),
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
