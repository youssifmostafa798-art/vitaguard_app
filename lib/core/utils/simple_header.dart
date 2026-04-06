import 'package:flutter/material.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_text.dart';

class SimpleHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final bool automaticallyImplyLeading;

  const SimpleHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(80); // height responsive

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: automaticallyImplyLeading
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xff0D3B66)),
                onPressed: onBackPressed ?? () => Navigator.pop(context),
              )
            : null,
        title: CustemText(
          text: title,
          color: const Color(0xff0D3B66),
          weight: FontWeight.bold,
          size: 18,
        ),
      ),
    );
  }
}
