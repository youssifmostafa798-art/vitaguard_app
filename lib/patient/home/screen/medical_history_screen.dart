import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/components/custem_field.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';
import 'package:vitaguard_app/patient/home/screen/medical_history_view_model.dart';
import 'package:vitaguard_app/patient/home/widget/name_card.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final String patientName;
  final String? patientId;
  
  const MedicalHistoryScreen({
    super.key,
    required this.patientName,
    this.patientId,
  });

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  late final MedicalHistoryViewModel _viewModel;

  final TextEditingController diabetes = TextEditingController();
  final TextEditingController metformin = TextEditingController();
  final TextEditingController dustmites = TextEditingController();

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _viewModel = MedicalHistoryViewModel(overridePatientId: widget.patientId);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _viewModel.fetchHistory();
      if (_viewModel.history != null && mounted) {
        setState(() {
          diabetes.text = _viewModel.history!.chronicDiseases ?? '';
          metformin.text = _viewModel.history!.medications ?? '';
          dustmites.text = _viewModel.history!.allergies ?? '';
          _isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    diabetes.dispose();
    metformin.dispose();
    dustmites.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  bool get _isNewRecord {
    if (_viewModel.history == null) return true;
    final h = _viewModel.history!;
    return (h.chronicDiseases ?? '').isEmpty && 
           (h.medications ?? '').isEmpty && 
           (h.allergies ?? '').isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: const SimpleHeader(title: "Medical history"),
          body: SafeArea(
            child: AppBackground(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(30),

                      NameCard(firstName: widget.patientName),

                      const Gap(30),

                      CustemField(
                        title: "Chronic Diseases",
                        hint: "No data available",
                        controller: diabetes,
                      ),

                      const Gap(20),

                      CustemField(
                        title: "Medications",
                        hint: "No data available",
                        controller: metformin,
                      ),

                      const Gap(20),

                      CustemField(
                        title: "Allergies",
                        hint: "No data available",
                        controller: dustmites,
                      ),

                      const Gap(30),

                      if (_viewModel.isLoading || !_isInitialized)
                        const Center(child: CircularProgressIndicator())
                      else
                        Button(
                          title: _isNewRecord ? "CREATE" : "SAVE",
                          onTap: () async {
                            final history = MedicalHistory(
                              chronicDiseases: diabetes.text,
                              medications: metformin.text,
                              allergies: dustmites.text,
                              surgeries: "",
                              notes: "",
                            );

                            final success = await _viewModel.saveHistory(history);

                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Medical history saved successfully!'),
                                ),
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_viewModel.error ?? 'Failed to update medical history'),
                                ),
                              );
                            }
                          },
                        ),
                        
                      const Gap(30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
