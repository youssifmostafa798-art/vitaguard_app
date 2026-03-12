import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_field.dart';
import 'package:vitaguard_app/core/simple_header.dart';

class ArchiveMedicalHistory extends StatefulWidget {
  final String diabetes;
  final String metformin;
  final String dustmites;

  const ArchiveMedicalHistory({
    super.key,
    required this.diabetes,
    required this.metformin,
    required this.dustmites,
  });

  @override
  State<ArchiveMedicalHistory> createState() => _ArchiveMedicalHistoryState();
}

class _ArchiveMedicalHistoryState extends State<ArchiveMedicalHistory> {
  late TextEditingController diabetesController;
  late TextEditingController metforminController;
  late TextEditingController dustmitesController;

  @override
  void initState() {
    super.initState();
    diabetesController = TextEditingController(text: widget.diabetes);
    metforminController = TextEditingController(text: widget.metformin);
    dustmitesController = TextEditingController(text: widget.dustmites);
  }

  @override
  void dispose() {
    diabetesController.dispose();
    metforminController.dispose();
    dustmitesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleHeader(title: "Medical history"),
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Gap(40),

                CustemField(
                  title: "Chronic Diseases",
                  hint: "",
                  controller: diabetesController,
                  readOnly: true,
                ),

                const Gap(20),

                CustemField(
                  title: "Medications",
                  hint: "",
                  controller: metforminController,
                  readOnly: true,
                ),

                const Gap(20),

                CustemField(
                  title: "Allergies",
                  hint: "",
                  controller: dustmitesController,
                  readOnly: true,
                ),

                const Spacer(),

                const Gap(30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



