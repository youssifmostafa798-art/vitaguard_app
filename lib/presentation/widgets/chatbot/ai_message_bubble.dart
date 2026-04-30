import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:vitaguard_app/data/models/chatbot/ai_chat_models.dart';
import 'package:vitaguard_app/features/chatbot/data/ai_response_sanitizer.dart';
import 'package:vitaguard_app/presentation/widgets/custem_text.dart';

class AiMessageBubble extends StatelessWidget {
  const AiMessageBubble({
    super.key,
    required this.message,
    required this.isPreviousSameSender,
  });

  final AiMessage message;
  final bool isPreviousSameSender;

  // ── Time formatting ────────────────────────────────────────────

  String _formatTime(DateTime createdAt) {
    final localTime = createdAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(
      localTime.year,
      localTime.month,
      localTime.day,
    );
    final timeStr = DateFormat('HH:mm').format(localTime);
    if (msgDay == today) return 'Today ' + timeStr;
    final yesterday = today.subtract(const Duration(days: 1));
    if (msgDay == yesterday) return 'Yesterday ' + timeStr;
    return DateFormat('MMM d, y').format(localTime) + ' ' + timeStr;
  }

  // ── Content ────────────────────────────────────────────────────

  String _prepareDisplayText() {
    if (message.content.trim().isEmpty && message.isStreaming) {
      return '_Thinking…_';
    }
    if (!message.isUser) {
      return AiResponseSanitizer.sanitize(message.content);
    }
    return message.content;
  }

  // ── Theme helpers ───────────────────────────────────────────────

  Color _bubbleColor() {
    if (message.isUser) return const Color(0xFF00A3FF);
    if (message.isError) return const Color(0xFFFFF1F1);
    return Colors.white;
  }

  Color _senderColor() {
    if (message.isUser) return Colors.white;
    if (message.isError) return const Color(0xFFC62828);
    return const Color(0xFF0D3B66);
  }

  Color _textColor() =>
      message.isUser ? Colors.white : const Color(0xFF1B263B);

  BorderRadius _bubbleBorderRadius() => BorderRadius.only(
        topLeft: Radius.circular(20.r),
        topRight: Radius.circular(20.r),
        bottomLeft: Radius.circular(message.isUser ? 20.r : 6.r),
        bottomRight: Radius.circular(message.isUser ? 6.r : 20.r),
      );

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isUser      = message.isUser;
    final displayText = _prepareDisplayText();
    final timeText    = _formatTime(message.createdAt);

    return Padding(
      padding: EdgeInsets.only(
        left:  isUser ? 52.w : 16.w,
        right: isUser ? 16.w : 52.w,
        top:   isPreviousSameSender ? 6.h : 16.h,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _buildAvatar(),
          if (!isUser) Gap(8.w),
          Flexible(child: _buildBubble(displayText, timeText, isUser)),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
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
    );
  }

  Widget _buildBubble(
    String displayText,
    String timeText,
    bool isUser,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _bubbleColor(),
        borderRadius: _bubbleBorderRadius(),
        border: isUser
            ? null
            : Border.all(
                color: message.isError
                    ? const Color(0xFFFFC2C2)
                    : const Color(0xFFE3EEF7),
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: CustemText(
                text: 'VitaGuard AI',
                size: 12,
                weight: FontWeight.w600,
                color: _senderColor(),
              ),
            ),
          _buildContent(displayText, isUser),
          if (message.isStreaming && message.content.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: SizedBox(
                width: 12.w,
                height: 12.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00A3FF),
                ),
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
    );
  }

  Widget _buildContent(String displayText, bool isUser) {
    if (isUser) {
      return Text(
        displayText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 15.sp,
          height: 1.4,
        ),
      );
    }
    return MarkdownBody(
      data: displayText,
      shrinkWrap: true,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: _textColor(),
          fontSize: 15.sp,
          height: 1.4,
        ),
        strong: TextStyle(
          color: _textColor(),
          fontWeight: FontWeight.bold,
          fontSize: 15.sp,
        ),
        em: TextStyle(
          color: _textColor(),
          fontStyle: FontStyle.italic,
          fontSize: 15.sp,
        ),
        listBullet: TextStyle(
          color: _textColor(),
          fontSize: 15.sp,
        ),
        blockquote: TextStyle(
          color: const Color(0xFF51617A),
          fontSize: 14.sp,
          fontStyle: FontStyle.italic,
        ),
        code: TextStyle(
          color: const Color(0xFF0D3B66),
          fontSize: 13.sp,
          backgroundColor: const Color(0xFFF1F5F9),
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8.r),
        ),
        h1: TextStyle(
          color: _textColor(),
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
        h2: TextStyle(
          color: _textColor(),
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
        h3: TextStyle(
          color: _textColor(),
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
