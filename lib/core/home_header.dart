import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/core/network/health_provider.dart';

class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  final String name_;
  final ImageProvider profileImage;
  final VoidCallback? onExit;

  const HomeHeader({
    super.key,
    required this.name_,
    required this.profileImage,
    this.onExit,
  });
  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(radius: 24, backgroundImage: profileImage),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Consumer<HealthProvider>(
                        builder: (context, health, _) => Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: health.isAiOnline ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustemText(
                        text: "Hello,",
                        color: Color(0xff003F6B),
                        size: 18,
                      ),
                      Row(
                        children: [
                          CustemText(
                            text: name_,
                            weight: FontWeight.bold,
                            color: Color(0xff003F6B),
                            size: 20,
                          ),
                          Gap(8),
                          Consumer<HealthProvider>(
                            builder: (context, health, _) => Tooltip(
                              message: health.aiMessage,
                              child: Icon(
                                Icons.bolt,
                                size: 16,
                                color: health.isAiOnline ? Colors.orange : Colors.grey,
                              ),
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
                    weight: 8,
                    size: 38,
                    color: Color(0xff003F6B),
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



