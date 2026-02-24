import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class InfoSlider extends StatelessWidget {
  final List<String> images;

  const InfoSlider({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const Gap(15),
        itemBuilder: (context, index) {
          return Container(
            width: 300,

            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
            clipBehavior: Clip.hardEdge,
            child: Image.asset(height: 120, images[index], fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}



