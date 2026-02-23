import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/compenets/custem_background.dart';
import 'package:vitaguard_app/compenets/custem_text.dart';

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
                CircleAvatar(radius: 24, backgroundImage: profileImage),
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
                      CustemText(
                        text: name_,
                        weight: FontWeight.bold,
                        color: Color(0xff003F6B),
                        size: 20,
                      ),
                    ],
                  ),
                ),
                Spacer(),
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
