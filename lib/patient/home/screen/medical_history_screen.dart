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
  const MedicalHistoryScreen._({
    super.key,
    this.patientName,
    required this.mode,
    this.patientId,
    this.initialHistory,
  });

  final String? patientName;
  final MedicalHistoryAccessMode mode;
  final String? patientId;
  final MedicalHistory? initialHistory;

  const MedicalHistoryScreen.forPatient({
    Key? key,
    required String patientName,
  }) : this._(
         key: key,
         patientName: patientName,
         mode: MedicalHistoryAccessMode.patient,
       );

  const MedicalHistoryScreen.forCompanion({
    Key? key,
    required String patientName,
    required String patientId,
  }) : this._(
         key: key,
         patientName: patientName,
         mode: MedicalHistoryAccessMode.companion,
         patientId: patientId,
       );

  const MedicalHistoryScreen.forDraft({
    Key? key,
    MedicalHistory? initialHistory,
  }) : this._(
         key: key,
         mode: MedicalHistoryAccessMode.draft,
         initialHistory: initialHistory,
       );

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
    switch (widget.mode) {
      case MedicalHistoryAccessMode.patient:
        _viewModel = MedicalHistoryViewModel.forPatient();
        break;
      case MedicalHistoryAccessMode.companion:
        _viewModel = MedicalHistoryViewModel.forCompanion(
          patientId: widget.patientId!,
        );
        break;
      case MedicalHistoryAccessMode.draft:
        _viewModel = MedicalHistoryViewModel.forDraft(
          initialHistory: widget.initialHistory,
        );
        break;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _viewModel.fetchHistory();
      if (!mounted) return;

      if (_viewModel.history != null) {
        _syncControllers(_viewModel.history!);
      } else {
        setState(() {
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

  void _syncControllers(MedicalHistory history) {
    setState(() {
      diabetes.text = history.chronicDiseases ?? '';
      metformin.text = history.medications ?? '';
      dustmites.text = history.allergies ?? '';
      _isInitialized = true;
    });
  }

  String get _buttonTitle {
    if (_viewModel.isDraftMode) {
      return 'CONFIRM';
    }
    return _viewModel.isCreateMode ? 'CREATE' : 'SAVE';
  }

  Future<void> _handleSubmit() async {
    final currentHistory = _viewModel.history ?? MedicalHistory.empty();
    final updatedHistory = currentHistory.copyWith(
      chronicDiseases: diabetes.text.trim(),
      medications: metformin.text.trim(),
      allergies: dustmites.text.trim(),
    );

    final success = await _viewModel.saveHistory(updatedHistory);
    if (!mounted) return;

    if (_viewModel.isDraftMode) {
      if (success) {
        Navigator.pop(context, updatedHistory);
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Medical history saved successfully!'
              : (_viewModel.error ?? 'Failed to update medical history'),
        ),
      ),
    );
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

                      if ((widget.patientName ?? '').isNotEmpty)
                        NameCard(firstName: widget.patientName!),

                      const Gap(30),

                      CustemField(
                        title: "Chronic Diseases",
                        hint: "No data available",
                        controller: diabetes,
                        readOnly: _viewModel.isReadOnly,
                      ),

                      const Gap(20),

                      CustemField(
                        title: "Medications",
                        hint: "No data available",
                        controller: metformin,
                        readOnly: _viewModel.isReadOnly,
                      ),

                      const Gap(20),

                      CustemField(
                        title: "Allergies",
                        hint: "No data available",
                        controller: dustmites,
                        readOnly: _viewModel.isReadOnly,
                      ),

                      const Gap(30),

                      if (_viewModel.isLoading || !_isInitialized)
                        const Center(child: CircularProgressIndicator())
                      else if (!_viewModel.isReadOnly)
                        Button(
                          title: _buttonTitle,
                          onTap: _handleSubmit,
                        ),
                      if ((_viewModel.error ?? '').isNotEmpty) ...[
                        const Gap(16),
                        Text(
                          _viewModel.error!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                      if (_viewModel.isReadOnly)
                        const Text(
                          'Companions can view medical history but cannot edit it.',
                          style: TextStyle(color: Color(0xff0D3B66)),
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
