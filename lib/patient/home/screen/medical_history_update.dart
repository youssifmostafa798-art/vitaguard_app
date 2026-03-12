import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/companion/home/widget/archive_medical_history.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_bottom.dart';
import 'package:vitaguard_app/core/simple_header.dart';
import 'package:vitaguard_app/components/custem_field.dart';
import 'package:vitaguard_app/patient/home/widget/name_card.dart';
import 'package:provider/provider.dart';
import 'package:vitaguard_app/patient/ui/patient_provider.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';

class MedicalHistoryUpdate extends StatefulWidget {
  final String firstNamee;

  const MedicalHistoryUpdate({super.key, required this.firstNamee});

  @override
  State<MedicalHistoryUpdate> createState() => _MedicalHistoryUpdateState();
}

class _MedicalHistoryUpdateState extends State<MedicalHistoryUpdate> {
  final TextEditingController diabetes = TextEditingController();
  final TextEditingController metformin = TextEditingController();
  final TextEditingController dustmites = TextEditingController();

  @override
  void dispose() {
    diabetes.dispose();
    metformin.dispose();
    dustmites.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

                  NameCard(firstName: widget.firstNamee),

                  const Gap(30),

                  CustemField(
                    title: "Chronic Diseases",
                    hint: "Diabetes",
                    controller: diabetes,
                  ),

                  const Gap(20),

                  CustemField(
                    title: "Medications",
                    hint: "Metformin",
                    controller: metformin,
                  ),

                  const Gap(20),

                  CustemField(
                    title: "Allergies",
                    hint: "Dust mites",
                    controller: dustmites,
                  ),

                  const Gap(30),

                  Consumer<PatientProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Button(
                        title: "Confirm",
                        onTap: () async {
                          final history = MedicalHistory(
                            chronicDiseases: diabetes.text,
                            medications: metformin.text,
                            allergies: dustmites.text,
                            surgeries: "", // UI doesn't have these yet
                            notes: "",
                          );

                          final success = await provider.updateMedicalHistory(
                            history,
                          );

                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Medical history updated successfully!',
                                ),
                              ),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ArchiveMedicalHistory(
                                  diabetes: diabetes.text,
                                  metformin: metformin.text,
                                  dustmites: dustmites.text,
                                ),
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.error ??
                                      'Failed to update medical history',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
