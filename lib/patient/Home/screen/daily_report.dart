import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:vitaguard_app/compenets/custem_background.dart';
import 'package:vitaguard_app/compenets/custem_bottom.dart';
import 'package:vitaguard_app/compenets/custem_field.dart';
import 'package:vitaguard_app/core/simple_header.dart';
import 'package:vitaguard_app/patient/ui/patient_provider.dart';
import 'package:vitaguard_app/patient/data/patient_models.dart';

class DailyReport extends StatefulWidget {
  const DailyReport({super.key});

  @override
  State<DailyReport> createState() => _DailyReportState();
}

class _DailyReportState extends State<DailyReport> {
  final _heartRateCtrl = TextEditingController();
  final _oxygenCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();

  void _handleSave() async {
    final provider = Provider.of<PatientProvider>(context, listen: false);

    final report = DailyReport(
      heartRate: double.tryParse(_heartRateCtrl.text) ?? 0,
      oxygenLevel: double.tryParse(_oxygenCtrl.text) ?? 0,
      temperature: double.tryParse(_tempCtrl.text) ?? 0,
      bloodPressure: _bpCtrl.text.trim(),
    );

    final success = await provider.submitDailyReport(report);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved successfully')),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save report')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<PatientProvider>(context).isLoading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(title: "Daily Report"),
      body: SafeArea(
        child: AppBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(30),

                      CustemField(
                        title: "Heart Rate (bpm)",
                        hint: "e.g. 75",
                        controller: _heartRateCtrl,
                      ),

                      const Gap(20),

                      CustemField(
                        title: "Oxygen Level (%)",
                        hint: "e.g. 98",
                        controller: _oxygenCtrl,
                      ),

                      const Gap(20),

                      CustemField(
                        title: "Temperature (°C)",
                        hint: "e.g. 36.5",
                        controller: _tempCtrl,
                      ),

                      const Gap(20),

                      CustemField(
                        title: "Blood Pressure",
                        hint: "e.g. 120/80",
                        controller: _bpCtrl,
                      ),

                      const Gap(40),

                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Button(title: "Save Report", onTap: _handleSave),

                      const Gap(30),
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
