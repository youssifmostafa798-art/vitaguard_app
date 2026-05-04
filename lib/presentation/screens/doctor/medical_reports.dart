import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/presentation/controllers/doctor/doctor_provider.dart';

import '../../../core/utils/custem_background.dart';
import '../../../core/utils/custem_bottom.dart';
import '../../../core/utils/custem_field.dart';

class MedicalReports extends ConsumerStatefulWidget {
  const MedicalReports({super.key});

  @override
  ConsumerState<MedicalReports> createState() => _MedicalReportsState();
}

class _MedicalReportsState extends ConsumerState<MedicalReports> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;
  bool _isPicking = false;
  File? _selectedFile;

  Future<void> _handleConfirm() async {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    setState(() => _isLoading = true);

    final success = await ref
        .read(doctorControllerProvider.notifier)
        .uploadMedicalReport(
          patientPhone: phone,
          patientName: name,
          description: desc,
          imageFile: _selectedFile,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical report uploaded successfully')),
      );
      Navigator.pop(context);
    } else {
      final errMsg =
          ref.read(doctorControllerProvider).error?.toString() ??
          'Failed to upload report';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errMsg)));
    }
  }

  Future<void> _pickImage() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
        });
      }
    } finally {
      setState(() => _isPicking = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(
        title: 'Medical Reports',
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

                      CustemField(
                        title: 'Mobile Number',
                        hint: "Enter Patient's Phone",
                        controller: _phoneController,
                      ),

                      Gap(20.h),
                      CustemField(
                        title: "Patient's Name",
                        hint: "Enter Patient's Name",
                        controller: _nameController,
                      ),

                      Gap(20.h),
                      CustemField(
                        title: 'Description',
                        hint: 'Enter Description',
                        controller: _descController,
                      ),

                      Gap(20.h),

                      // Image upload area
                      GestureDetector(
                        onTap: _isPicking ? null : _pickImage,
                        child: Container(
                          height: 180.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xff0D3B66)),
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                          child: _selectedFile != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: Image.file(
                                        _selectedFile!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => _selectedFile = null,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.white70,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Color(0xff0D3B66),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 50,
                                        color: const Color(0xff0D3B66),
                                      ),
                                      const Gap(8),
                                      const Text(
                                        'Tap to select image',
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

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Button(title: 'Confirm', onTap: _handleConfirm),

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
