import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/presentation/widgets/custem_background.dart';
import 'package:vitaguard_app/presentation/widgets/custem_bottom.dart';
import 'package:vitaguard_app/presentation/widgets/custem_text.dart';
import 'package:vitaguard_app/presentation/widgets/custom_logo.dart';

//import 'package:vitaguard_app/presentation/screens/doctor/doctor_home.dart';

class ConsultationOptionsScreen extends StatefulWidget {
  const ConsultationOptionsScreen({super.key});

  @override
  State<ConsultationOptionsScreen> createState() =>
      _ConsultationOptionsScreenState();
}

class _ConsultationOptionsScreenState extends State<ConsultationOptionsScreen> {
  String selectedOption = "1";
  final TextEditingController otherController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  Widget optionItem(String text) {
    final bool isSelected = selectedOption == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOption = text;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade400,
            width: 1.5,
          ),
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.blue : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              VitaGuardLogo(size: 20),
              CustemText(
                text: "Consultation Options",
                size: 22,
                weight: FontWeight.w900,
                color: Color(0xff003F6B),
              ),

              Gap(20),

              optionItem("1"),
              optionItem("2"),
              optionItem("3"),
              optionItem("Unlimited"),
              optionItem("Other - Enter number"),

              if (selectedOption == "Other - Enter number")
                TextField(
                  controller: otherController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter Number",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              Gap(20),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter Price",
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Gap(20),
              Button(
                title: "Confirm",
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
