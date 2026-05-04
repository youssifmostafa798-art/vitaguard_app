import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';

import '../../../core/utils/custem_background.dart';
import '../../../core/utils/custem_bottom.dart';
import '../../../core/utils/custem_text.dart';

class ImageOfTheRecord extends StatefulWidget {
  final File? initialImage;

  const ImageOfTheRecord({super.key, this.initialImage});

  @override
  State<ImageOfTheRecord> createState() => _ImageOfTheRecordState();
}

class _ImageOfTheRecordState extends State<ImageOfTheRecord> {
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
      appBar: SimpleHeader(title: "Facility Record Image"),
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Gap(40.h),

                const CustemText(
                  text: "Upload Facility Record Image",
                  size: 18,
                  color: Color(0xff003F6B),
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
