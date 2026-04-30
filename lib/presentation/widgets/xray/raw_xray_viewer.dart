import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: Colors.grey.shade300,
              child: Center(
                child: Icon(Icons.broken_image_outlined, size: 48.sp),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
