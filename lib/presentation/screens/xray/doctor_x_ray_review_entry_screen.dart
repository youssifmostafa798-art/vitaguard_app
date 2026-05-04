import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/presentation/screens/xray/doctor_two_phase_review_screen.dart';

import '../../../core/utils/custem_background.dart';

/// Doctor-tab host: pick an X-ray, then run the mandatory two-phase review flow.
///
/// REASON: `IndexedStack` in [MainDoctor] has no nested [Navigator]; embedding the
/// review screen here avoids route complexity while keeping AI gated after Phase 1.
class DoctorXRayReviewEntryScreen extends StatefulWidget {
  const DoctorXRayReviewEntryScreen({super.key});

  @override
  State<DoctorXRayReviewEntryScreen> createState() =>
      _DoctorXRayReviewEntryScreenState();
}

class _DoctorXRayReviewEntryScreenState
    extends State<DoctorXRayReviewEntryScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _imageFile = File(image.path));
  }

  void _clearAndPickAnother() {
    setState(() => _imageFile = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(
        title: 'X-Ray review',
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: AppBackground(
          child: _imageFile == null
              ? _buildPicker(context)
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _clearAndPickAnother,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Change image'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: DoctorTwoPhaseReviewScreen(
                        key: ValueKey(_imageFile!.path),
                        xRayFile: _imageFile!,
                        onReviewFinished: _clearAndPickAnother,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPicker(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Gap(24.h),
          Text(
            'Two-phase clinical review',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Gap(8.h),
          Text(
            'Select a study image. You will complete a manual assessment first; '
            'AI assistance unlocks only after that step.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          Gap(28.h),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 280.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.primary, width: 1.2),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 56.sp, color: Colors.grey),
                    Gap(12.h),
                    Text(
                      'Tap to select X-ray',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Gap(40.h),
        ],
      ),
    );
  }
}
