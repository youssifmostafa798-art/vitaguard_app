import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/core/utils/avatar_color.dart';
import 'package:vitaguard_app/models/message_model.dart';

//const
class ChatPreviewCard extends StatelessWidget {
  final ChatPreview chat;
  final VoidCallback onTap;

  const ChatPreviewCard({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 24.r,
              backgroundColor: getAvatarColor(chat.sender),
              child: CustemText(
                text: chat.avatarInitials,
                weight: FontWeight.bold,
                size: 16,
              ),
            ),
            Gap(12.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustemText(
                        text: chat.name,
                        size: 16,
                        weight: FontWeight.w600,
                        color: Color(0xff003F6B),
                      ),
                      CustemText(
                        text: chat.time,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  Gap(4),
                  Row(
                    children: [
                      if (chat.sender == MessageSender.user)
                        const Icon(Icons.check, size: 16, color: Colors.grey),
                      if (chat.sender == MessageSender.user) const Gap(4),
                      Expanded(
                        child:
                            // Leave it as it is
                            Text(
                              chat.lastMessage,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: chat.unreadCount > 0
                                    ? Colors.black
                                    : Colors.grey[600],
                                fontWeight: chat.unreadCount > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00A3FF),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            chat.unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
