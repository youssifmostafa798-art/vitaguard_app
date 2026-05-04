import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/features/patient/data/home_guidance_video.dart';
import 'package:vitaguard_app/presentation/widgets/patient/guidance_video_card.dart';

import '../../../core/utils/custem_background.dart';

class GuidanceVideos extends StatelessWidget {
  const GuidanceVideos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleHeader(title: "Guidance Videos"),
      body: SafeArea(
        child: AppBackground(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
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
