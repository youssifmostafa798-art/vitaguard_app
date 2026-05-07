import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/core/feedback/clinical_feedback.dart';

/// Raw image only — no AI overlays (Phase 1).
class RawXRayViewer extends StatelessWidget {
  const RawXRayViewer({super.key, required this.imageFile});

  final File imageFile;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: AspectRatio(
        aspectRatio: 1,
        child: RepaintBoundary(
          child: Image.file(
            imageFile,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Padding(
              padding: EdgeInsets.all(12.r),
              child: const ClinicalFeedbackPanel(
                type: ClinicalPopupType.warning,
                title: 'Image Unavailable',
                message: 'Unable to preview this X-ray image.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
