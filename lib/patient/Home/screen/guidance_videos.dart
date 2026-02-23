import 'package:flutter/material.dart';
import 'package:vitaguard_app/compenets/custem_background.dart';
import 'package:vitaguard_app/core/simple_header.dart';
import 'package:vitaguard_app/patient/data/home_guidance_video.dart';
import 'package:vitaguard_app/patient/Home/widget/guidance_video_card.dart';

class GuidanceVideos extends StatelessWidget {
  const GuidanceVideos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleHeader(title: "Guidance Videos"),
      body: SafeArea(
        child: AppBackground(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: guidanceVideos.length,
            itemBuilder: (context, index) {
              return GuidanceVideoCard(video: guidanceVideos[index]);
            },
          ),
        ),
      ),
    );
  }
}
