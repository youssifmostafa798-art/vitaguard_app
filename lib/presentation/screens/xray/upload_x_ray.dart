import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vitaguard_app/presentation/widgets/custem_background.dart';
import 'package:vitaguard_app/presentation/widgets/custem_bottom.dart';
import 'package:vitaguard_app/presentation/widgets/custem_text.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/presentation/screens/xray/ai_xray_result_screen.dart';
import 'package:vitaguard_app/presentation/controllers/patient/patient_provider.dart';

class UploadXRay extends ConsumerStatefulWidget {
  const UploadXRay({
    super.key,
    this.patientId,
    this.patientName,
    this.requiresPatientContext = false,
  });

  final String? patientId;
  final String? patientName;
  final bool requiresPatientContext;

  @override
  ConsumerState<UploadXRay> createState() => _UploadXRayState();
}

class _UploadXRayState extends ConsumerState<UploadXRay> {
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
    if (widget.requiresPatientContext &&
        (widget.patientId == null || widget.patientId!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Linked patient is still syncing.')),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an X-ray image first')),
      );
      return;
    }

    final success = await ref
        .read(patientControllerProvider.notifier)
        .analyzeXRay(_selectedImage!, patientId: widget.patientId);

    if (success) {
      if (!mounted) return;
      final result = ref.read(patientControllerProvider).lastXRayResult;
      if (result == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AiXRayResultScreen(
            imageFile: _selectedImage!,
            result: result,
            onRetry: () async {
              Navigator.pop(context);
              _handleScan();
            },
          ),
        ),
      );
    } else {
      if (!mounted) return;
      final provider = ref.read(patientControllerProvider.notifier);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(patientControllerProvider).error?.toString() ?? 'Analysis failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(patientControllerProvider).isLoading;

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
                      //Upload the X-ray
                      CustemText(
                        text: widget.patientName == null
                            ? "Upload the X-ray"
                            : "Upload ${widget.patientName}'s X-ray",
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
                                      //Tap to select image
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
                        Column(
                          children: [
                            const CircularProgressIndicator(),
                            const Gap(12),
                            Text(
                              'Analyzing image...',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              '(this usually takes 5-15 seconds)',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
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