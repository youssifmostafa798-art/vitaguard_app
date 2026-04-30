import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:vitaguard_app/data/models/chatbot/ai_chat_models.dart';
import 'package:vitaguard_app/presentation/widgets/custem_text.dart';

class AiMessageBubble extends StatelessWidget {
  final AiMessage message;
  final bool isPreviousSameSender;

  const AiMessageBubble({
    super.key,
    required this.message,
    required this.isPreviousSameSender,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final senderName = isUser ? 'You' : 'VitaGuard AI';
    final bubbleColor = isUser
        ? const Color(0xFF00A3FF)
        : (message.isError ? const Color(0xFFFFF1F1) : Colors.white);
    final senderColor = isUser
        ? Colors.white
        : (message.isError ? const Color(0xFFC62828) : const Color(0xFF0D3B66));
    final textColor = isUser ? Colors.white : const Color(0xFF1B263B);
    
    final localTime = message.createdAt.toLocal();
    final now = DateTime.now();
    final isToday = localTime.year == now.year && localTime.month == now.month && localTime.day == now.day;
    final isYesterday = localTime.year == now.year && localTime.month == now.month && localTime.day == now.day - 1;
    final timeStr = DateFormat('HH:mm').format(localTime);
    String timeText;
    if (isToday) {
      timeText = 'Today $timeStr';
    } else if (isYesterday) {
      timeText = 'Yesterday $timeStr';
    } else {
      timeText = '${DateFormat('MMM d, y').format(localTime)} $timeStr';
    }
    
    final displayText = message.content.trim().isEmpty && message.isStreaming
        ? 'Thinking...'
        : message.content;

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 52.w : 16.w,
        right: isUser ? 16.w : 52.w,
        top: isPreviousSameSender ? 6.h : 16.h,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: message.isError
                    ? const Color(0xFFFFDAD6)
                    : const Color(0xFF5CEAD2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Icon(
                  Icons.health_and_safety,
                  color: const Color(0xFF0D3B66),
                  size: 20.r,
                ),
              ),
            ),
          if (!isUser) Gap(8.w),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                  bottomLeft: Radius.circular(isUser ? 20.r : 6.r),
                  bottomRight: Radius.circular(isUser ? 6.r : 20.r),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: message.isError
                            ? const Color(0xFFFFC2C2)
                            : const Color(0xFFE3EEF7),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: CustemText(
                        text: senderName,
                        size: 12,
                        weight: FontWeight.w600,
                        color: senderColor,
                      ),
                    ),
                  MarkdownBody(
                    data: displayText,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: textColor, fontSize: 15.sp, height: 1.4),
                      strong: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15.sp),
                      em: TextStyle(color: textColor, fontStyle: FontStyle.italic, fontSize: 15.sp),
                      listBullet: TextStyle(color: textColor, fontSize: 15.sp),
                    ),
                  ),
                  if (message.isStreaming && message.content.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: SizedBox(
                        width: 12.w,
                        height: 12.w,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A3FF)),
                      ),
                    ),
                  if (message.isError && message.errorMessage != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: CustemText(
                        text: message.errorMessage!,
                        size: 11,
                        color: const Color(0xFFC62828),
                      ),
                    ),
                  Gap(4.h),
                  CustemText(
                    text: timeText,
                    size: 10,
                    color: isUser ? Colors.white70 : const Color(0xFF6B7A90),
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
