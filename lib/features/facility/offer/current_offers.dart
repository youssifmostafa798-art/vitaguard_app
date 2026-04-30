import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/features/facility/offer/add_offer.dart';
import 'package:vitaguard_app/presentation/widgets/custem_background.dart';
import 'package:vitaguard_app/presentation/widgets/custem_bottom.dart';
import 'package:vitaguard_app/presentation/widgets/custem_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CurrentOffers extends StatefulWidget {
  const CurrentOffers({super.key});

  @override
  State<CurrentOffers> createState() => _CurrentOffersState();
}

class _CurrentOffersState extends State<CurrentOffers> {
  final List<String> offers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeader(
        title: "Current Offers",
        automaticallyImplyLeading: false,
      ),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ...offers.map(
                (offer) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustemField(
                          title: "",
                          hint: offer,
                          readOnly: true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Color(0xff003F6B),
                        ),
                        onPressed: () {
                          //enable to edit
                          setState(() {
                            offers.remove(offer);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              Gap(300.h),

              Button(
                title: "Create",
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddOffer()),
                  );

                  if (result != null && result.toString().isNotEmpty) {
                    setState(() {
                      offers.add(result);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}