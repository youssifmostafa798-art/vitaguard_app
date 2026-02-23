import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/compenets/custem_background.dart';
import 'package:vitaguard_app/compenets/custem_bottom.dart';
import 'package:vitaguard_app/compenets/custem_field.dart';
import 'package:vitaguard_app/core/simple_header.dart';

class DailyReport extends StatelessWidget {
  const DailyReport({super.key});

  @override
  Widget build(BuildContext context) {
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

                      /// Fields
                      const CustemField(title: "Date/ Day", hint: ""),

                      const Gap(20),

                      const CustemField(title: "Tasks / Activities", hint: ""),

                      const Gap(20),

                      const CustemField(title: "Notes / Comments", hint: ""),

                      Gap(300),
                      Button(
                        title: "Save",
                        onTap: () {
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
