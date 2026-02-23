import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/compenets/custem_background.dart';
import 'package:vitaguard_app/compenets/custem_bottom.dart';
import 'package:vitaguard_app/compenets/custem_field.dart';
import 'package:vitaguard_app/core/simple_header.dart';

class Reports extends StatelessWidget {
  const Reports({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SimpleHeader(
        title: "Add Report",
        automaticallyImplyLeading: false,
      ),
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
                      const Gap(20),

                      /// Fields
                      const CustemField(title: "mobile number", hint: ""),

                      const Gap(20),

                      const CustemField(title: "Patient's name", hint: ""),

                      const Gap(20),

                      const CustemField(title: "Upload image OR PDF", hint: ""),
                      const Gap(20),

                      TextField(
                        readOnly: true,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: "Upload image OR PDF",
                          suffixIcon: Icon(Icons.image_outlined, size: 40),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),

                      Gap(110),
                      Button(
                        title: "Confirm",
                        onTap: () {
                          //edit
                          Navigator.pop(context);
                        },
                      ),

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
