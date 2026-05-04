import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/core/utils/simple_buttom.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/presentation/controllers/patient/patient_provider.dart';

import '../../../core/utils/custem_background.dart';
import '../../../core/utils/custem_text.dart';

class CompanionCode extends ConsumerStatefulWidget {
  const CompanionCode({super.key});

  @override
  ConsumerState<CompanionCode> createState() => _CompanionCodeState();
}

class _CompanionCodeState extends ConsumerState<CompanionCode> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patientControllerProvider.notifier).fetchCompanionCode();
    });
  }

  Future<void> _regenerateCode() async {
    final success = await ref
        .read(patientControllerProvider.notifier)
        .regenerateCompanionCode();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Companion code regenerated successfully"),
        ),
      );
    }
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Code copied to clipboard")));
  }

  @override
  Widget build(BuildContext context) {
    final patient = ref.watch(patientControllerProvider);
    final displayCode = patient.companionCode ?? "......";

    return Scaffold(
      appBar: SimpleHeader(title: "Companion Code"),
      body: SafeArea(
        child: AppBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(50),

                //Code
                CustemText(
                  text: "Code",
                  size: 18,
                  color: const Color(0xff0E3C63),
                  weight: FontWeight.bold,
                ),

                const Gap(10),

                GestureDetector(
                  onLongPress: () => _copyToClipboard(displayCode),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xff0E3C63)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustemText(
                            text: displayCode,
                            size: 24,
                            color: Colors.black,
                            weight: FontWeight.w700,
                          ),
                        ),
                        if (patient.isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          //copy
                          IconButton(
                            icon: const Icon(
                              Icons.copy,
                              size: 20,
                              color: Color(0xff0E3C63),
                            ),
                            onPressed: () => _copyToClipboard(displayCode),
                          ),
                      ],
                    ),
                  ),
                ),

                const Gap(30),

                //Change Code
                SimpleButtom(
                  text: patient.isLoading ? "Regenerating..." : "Change Code",
                  onTap: patient.isLoading ? null : _regenerateCode,
                ),

                if (patient.error?.toString() != null) ...[
                  const Gap(10),
                  Text(
                    patient.error?.toString() ?? '',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
