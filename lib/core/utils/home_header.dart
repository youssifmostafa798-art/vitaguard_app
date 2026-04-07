import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/core/providers.dart';

class HomeHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String name_;
  final VoidCallback? onExit;

  const HomeHeader({super.key, required this.name_, this.onExit});

  @override
  Size get preferredSize => Size.fromHeight(80.h);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthProvider);

    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Stack(
                  children: [
                    // Fixed default avatar using Icons.person
                    CircleAvatar(
                      radius: 24.r,
                      backgroundColor: Colors.grey, // Neutral background
                      child: Icon(
                        Icons.person,
                        size: 42.r,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14.r,
                        height: 14.r,
                        decoration: BoxDecoration(
                          color: health.isAiOnline ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CustemText(
                        text: "Hello,",
                        color: Color(0xff003F6B),
                        size: 18,
                      ),
                      Row(
                        children: [
                          CustemText(
                            text: name_,
                            weight: FontWeight.bold,
                            color: const Color(0xff003F6B),
                            size: 20,
                          ),
                          Gap(2.w),
                          Tooltip(
                            message: health.aiMessage,
                            child: Icon(
                              Icons.bolt,
                              size: 16.r,
                              color: health.isAiOnline
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onExit,
                  tooltip: "Exit",
                  icon: Icon(
                    Icons.exit_to_app,
                    size: 38.r,
                    color: const Color(0xff003F6B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
