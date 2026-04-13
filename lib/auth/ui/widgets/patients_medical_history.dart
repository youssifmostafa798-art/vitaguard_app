import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custom_logo.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/patient/data/patient_repository.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final _repository = PatientRepository();
  final _chronicController = TextEditingController();
  final _medicationsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;

  bool get _isLoggedIn => SupabaseService.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!_isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final history = await _repository.getMedicalHistory();
      _chronicController.text = history.chronicDiseases ?? '';
      _medicationsController.text = history.medications ?? '';
    } catch (e) {
      // Ignore errors for new users
    } finally {
      setState(() => _isLoading = false);
    }
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

  Future<void> _saveData() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final history = MedicalHistory(
      chronicDiseases: _chronicController.text,
      medications: _medicationsController.text,
      allergies: "",
      surgeries: "",
      notes: "",
    );

    try {
      if (!_isLoggedIn) {
        if (mounted) {
          Navigator.pop(context, history);
        }
        return;
      }

      await _repository.updateMedicalHistory(history);

      if (_selectedImage != null) {
        await _repository.uploadMedicalDocument(_selectedImage!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical history updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  VitaGuardLogo(size: 100),
                  Gap(20.h),
                  _box(
                    hint: "Chronic diseases",
                    controller: _chronicController,
                  ),
                  Gap(16.h),
                  _box(hint: "Medications", controller: _medicationsController),
                  Gap(16.h),

                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedImage != null
                                  ? _selectedImage!.path.split('/').last
                                  : "X-ray or lab tests (optional)",
                              style: TextStyle(
                                color: _selectedImage != null
                                    ? Colors.black
                                    : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.image_outlined,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),

                  Gap(40.h),

                  _isSaving
                      ? const CircularProgressIndicator()
                      : Button(title: "Confirm", onTap: _saveData),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _box({
    required String hint,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chronicController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }
}
