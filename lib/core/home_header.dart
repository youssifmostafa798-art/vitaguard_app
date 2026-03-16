import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/core/providers.dart';

class HomeHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String name_;
  final VoidCallback? onExit;

  const HomeHeader({super.key, required this.name_, this.onExit});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthProvider);

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
                    // Fixed default avatar using Icons.person
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey, // Neutral background
                      child: Icon(Icons.person, size: 42, color: Colors.white),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: health.isAiOnline ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(12),
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
                          const Gap(8),
                          Tooltip(
                            message: health.aiMessage,
                            child: Icon(
                              Icons.bolt,
                              size: 16,
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
                  icon: const Icon(
                    Icons.exit_to_app,
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
