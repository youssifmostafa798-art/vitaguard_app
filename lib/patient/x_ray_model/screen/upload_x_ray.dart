import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/patient/ui/patient_provider.dart';
import 'package:vitaguard_app/patient/home/widget/radiology_result.dart';

class UploadXRay extends StatefulWidget {
  const UploadXRay({super.key});

  @override
  State<UploadXRay> createState() => _UploadXRayState();
}

class _UploadXRayState extends State<UploadXRay> {
  File? _selectedImage;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _handleScan() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an X-ray image first')),
      );
      return;
    }

    final provider = Provider.of<PatientProvider>(context, listen: false);
    // We'll use the repository indirectly through the provider
    // For now, let's assume we add a method to PatientProvider
    final success = await provider.analyzeXRay(_selectedImage!);

    if (success) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RadiologyResult(result: provider.lastXRayResult!),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Analysis failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<PatientProvider>(context).isLoading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                      const Gap(20),
                      CustemText(
                        text: "Upload the X-ray",
                        size: 20,
                        weight: FontWeight.w600,
                        color: const Color(0xff003F6B),
                      ),
                      const Gap(30),

                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                            image: _selectedImage != null
                                ? DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            border: Border.all(
                              color: const Color(0xff003F6B),
                              width: 1.2,
                            ),
                          ),
                          child: _selectedImage == null
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                      Gap(8),
                                      Text(
                                        "Tap to select image",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      ),

                      const Gap(50),

                      if (isLoading)
                        const CircularProgressIndicator()
                      else
                        Button(title: 'Scan', onTap: _handleScan),
                      const Gap(20),
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
