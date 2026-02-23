import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/compenets/custem_background.dart';
import 'package:vitaguard_app/compenets/custem_bottom.dart';
import 'package:vitaguard_app/compenets/custem_field.dart';
import 'package:vitaguard_app/core/simple_header.dart';

class AddOffer extends StatelessWidget {
  AddOffer({super.key});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeader(title: "Add Offer"),
      body: SafeArea(
        child: AppBackground(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Gap(30),

                  CustemField(
                    title: "Display Name",
                    hint: "",
                    controller: nameController,
                  ),
                  const Gap(20),

                  CustemField(
                    title: "Display Details",
                    hint: "",
                    controller: detailsController,
                  ),
                  const Gap(20),

                  CustemField(
                    title: "Discount Percentage",
                    hint: "",
                    controller: discountController,
                  ),
                  const Gap(20),

                  CustemField(
                    title: "Original Price",
                    hint: "",
                    controller: priceController,
                  ),
                  Gap(20),
                  TextField(
                    readOnly: true,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: "Upload Cover Image",
                      suffixIcon: Icon(Icons.image_outlined, size: 40),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),

                  const Gap(70),

                  Button(
                    title: "Save",
                    onTap: () {
                      // نرجع اسم العنصر
                      Navigator.pop(context, nameController.text);
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
