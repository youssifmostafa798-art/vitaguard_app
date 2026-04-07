import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/models/message_model.dart';

class MessageDrBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isPreviousSameSender;
  final String drName;

  const MessageDrBubble({
    super.key,
    required this.message,
    this.isPreviousSameSender = false,
    required this.drName,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final isPatient = message.sender == MessageSender.patient;
    final isLab = message.sender == MessageSender.facility;

    String senderName = '';
    Color senderColor = const Color(0xFF00A3FF);

    if (isPatient) {
      senderName = drName;
      senderColor = const Color(0xFF00A3FF);
    } else if (isLab) {
      senderName = 'Medical Laboratory';
      senderColor = const Color(0xFF9C27B0);
    }

    String senderInitial = '';
    if (isPatient && drName.isNotEmpty) {
      senderInitial = drName.trim().isNotEmpty
          ? drName.trim()[0].toUpperCase()
          : 'D';
    } else if (isLab) {
      senderInitial = 'L';
    }

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 50.w : 16.w,
        right: isUser ? 16.w : 50.w,
        top: isPreviousSameSender ? 4.h : 16.h,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for non-user messages (patient or lab)
          if (!isUser && !isPreviousSameSender)
            CircleAvatar(
              radius: 16.r,
              backgroundColor: senderColor,
              child: CustemText(
                text: senderInitial,
                size: 12,
                color: Colors.white,
                weight: FontWeight.w600,
              ),
            ),
          if (!isUser && !isPreviousSameSender) Gap(8.w),

          // Message bubble
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF00A3FF) : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                  bottomLeft: Radius.circular(isUser ? 20.r : 4.r),
                  bottomRight: Radius.circular(isUser ? 4.r : 20.r),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show sender name for first message from doctor/lab
                  if (!isUser && !isPreviousSameSender)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: CustemText(
                        text: senderName,
                        size: 12,
                        weight: FontWeight.w600,
                        color: senderColor,
                      ),
                    ),

                  // Message content
                  CustemText(
                    text: message.content,
                    color: isUser ? Colors.white : Colors.black87,
                    size: 15,
                  ),

                  Gap(4.h),

                  // Time and read status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustemText(
                        text: message.time,
                        size: 10,
                        color: isUser ? Colors.white70 : Colors.grey.shade600,
                      ),
                      if (isUser) ...[
                        Gap(4.w),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14.r,
                          color: message.isRead ? Colors.white : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
