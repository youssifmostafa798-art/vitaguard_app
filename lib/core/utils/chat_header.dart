import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_text.dart';

class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final String namee;
  final VoidCallback? onBackPressed;

  const ChatHeader({super.key, required this.namee, this.onBackPressed});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 16.h);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: const BoxDecoration(
          color: Color(0xff5CEAD2),
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        child: Row(
          children: [
            // Back button
            IconButton(
              onPressed: onBackPressed ?? () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: const Color(0xFF333333),
                size: 20.r,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),

            SizedBox(width: 12.w),

            // Doctor avatar
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                color: const Color(0xFF00A3FF),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: CustemText(
                  text: _getInitials(namee),
                  size: 18,
                  color: Colors.white,
                  weight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // Doctor info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                //mainAxisSize: MainAxisSize.min,
                children: [
                  Gap(6.h),
                  CustemText(
                    text: namee,
                    size: 16,
                    weight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),

                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Gap(10.w),
                      CustemText(
                        text: "Online",
                        size: 12,
                        color: Color(0xFF666666),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Optional actions
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    // voice call action
                  },
                  icon: Icon(
                    Icons.call,
                    color: const Color(0xFF00A3FF),
                    size: 24.r,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: 16.w),
                IconButton(
                  onPressed: () {
                    // Video call action
                  },
                  icon: Icon(
                    Icons.videocam_rounded,
                    color: const Color(0xFF00A3FF),
                    size: 24.r,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  //error

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return '';
  }
}
