import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/components/custom_logo.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';

import '../../../core/utils/simple_header.dart';



class ProfessionalId extends StatefulWidget {
  final File? initialImage;

  const ProfessionalId({super.key, this.initialImage});

  @override
  State<ProfessionalId> createState() => _ProfessionalIdState();
}

class _ProfessionalIdState extends State<ProfessionalId> {
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar:   SimpleHeader(title: " Professional Association ID"),
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [

                Gap(40.h),

                CustemText(
                  text: "Upload Professional Association ID card.",
                  color: Color(0xff003F6B),
                  size: 18,
                  weight: FontWeight.bold,
                ),
                Gap(20.h),

                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),

              Gap(40.h),

                Button(
                  title: "Confirm",
                  onTap: () {
                    Navigator.pop(context, _selectedImage);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
