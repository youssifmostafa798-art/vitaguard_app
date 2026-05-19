import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:vitaguard_app/data/models/chatbot/ai_chat_models.dart';
import 'package:vitaguard_app/features/chatbot/domain/models/chat_message_model.dart';
import 'package:vitaguard_app/presentation/controllers/chatbot/ai_chat_provider.dart';
import '../shared/clinical_cards.dart';

import '../../../core/utils/custem_text.dart';

class AiMessageBubble extends ConsumerWidget {
  const AiMessageBubble({
    super.key,
    required this.message,
    required this.isPreviousSameSender,
    required this.isLastMessage,
    this.allowQuickReplies = true,
  });

  final AiMessage message;
  final bool isPreviousSameSender;
  final bool isLastMessage;
  final bool allowQuickReplies;

  // ── Time formatting ────────────────────────────────────────────

  String _formatTime(DateTime createdAt) {
    final localTime = createdAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(localTime.year, localTime.month, localTime.day);
    final timeStr = DateFormat('HH:mm').format(localTime);
    if (msgDay == today) return 'Today $timeStr';
    final yesterday = today.subtract(const Duration(days: 1));
    if (msgDay == yesterday) return 'Yesterday $timeStr';
    return '${DateFormat('MMM d, y').format(localTime)} $timeStr';
  }

  // ── Theme helpers ───────────────────────────────────────────────

  Color _senderColor() {
    if (message.isUser) return Colors.white;
    if (message.isError) return const Color(0xFFC62828);
    return const Color(0xFF0D3B66);
  }

  Color _textColor() => message.isUser ? Colors.white : const Color(0xFF1B263B);

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.isUser;
    final timeText = _formatTime(message.createdAt);
    
    final parsedMessage = ref.read(aiChatControllerProvider.notifier).getParsedMessage(message);

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
          if (!isUser) _buildAvatar(),
          if (!isUser) Gap(8.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBubbleContent(timeText, parsedMessage, isUser),
                if (!isUser &&
                    allowQuickReplies &&
                    message.status == AiMessageStatus.complete &&
                    message.quickReplies != null &&
                    message.quickReplies!.isNotEmpty &&
                    isLastMessage)
                  _buildQuickReplies(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: message.quickReplies!.map((reply) {
          return ActionChip(
            label: Text(
              reply,
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF003F6B),
              ),
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF00A3FF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            onPressed: () {
              // Send the quick reply message
              if (!ref.read(aiChatControllerProvider).isSending) {
                ref.read(aiChatControllerProvider.notifier).sendMessage(reply);
              }
            },
          );
        }).toList(),
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

  Widget _buildBubbleContent(String timeText, ChatMessageModel parsedMessage, bool isUser) {
    if (isUser) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFF00A3FF),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: Radius.circular(20.r),
            bottomRight: Radius.circular(6.r),
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              parsedMessage.text,
              style: TextStyle(color: Colors.white, fontSize: 15.sp, height: 1.4),
            ),
            Gap(4.h),
            CustemText(
              text: timeText,
              size: 10,
              color: Colors.white70,
            ),
          ],
        ),
      );
    }

    // AI Response Handling
    if (parsedMessage.text.isEmpty && message.isStreaming) {
      return _buildAiWrapper(
        timeText: timeText,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: _defaultAiBoxDecoration(),
          child: Text(
            '_Thinking…_',
            style: TextStyle(
              fontSize: 15.sp,
              color: _textColor(),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    if (!parsedMessage.isValid) {
      return _buildAiWrapper(
        timeText: timeText,
        child: const AlertCard(
          child: Text(
            "I'm sorry, I couldn't process that response correctly. Please try again.",
            style: TextStyle(color: Color(0xFFC62828)),
          ),
        ),
      );
    }

    Widget contentBody = _buildBlocks(parsedMessage.blocks);

    // Apply specific intent wrapper
    Widget wrappedContent;
    switch (parsedMessage.intent) {
      case MessageIntent.emergency:
        wrappedContent = AlertCard(child: contentBody);
        break;
      case MessageIntent.warning:
        wrappedContent = WarningCard(child: contentBody);
        break;
      case MessageIntent.tip:
        wrappedContent = InfoCard(child: contentBody);
        break;
      case MessageIntent.question:
      case MessageIntent.normal:
        wrappedContent = Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: _defaultAiBoxDecoration(),
          child: contentBody,
        );
        break;
    }

    return _buildAiWrapper(
      timeText: timeText,
      customWrapper: parsedMessage.intent == MessageIntent.normal || parsedMessage.intent == MessageIntent.question,
      child: wrappedContent,
    );
  }

  BoxDecoration _defaultAiBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.r),
        topRight: Radius.circular(20.r),
        bottomLeft: Radius.circular(6.r),
        bottomRight: Radius.circular(20.r),
      ),
      border: Border.all(
        color: message.isError ? const Color(0xFFFFC2C2) : const Color(0xFFE3EEF7),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildAiWrapper({
    required String timeText,
    required Widget child,
    bool customWrapper = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 4.h, left: customWrapper ? 16.w : 4.w),
          child: CustemText(
            text: 'VitaGuard AI',
            size: 12,
            weight: FontWeight.w600,
            color: _senderColor(),
          ),
        ),
        child,
        if (message.isStreaming && message.content.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8.h, left: customWrapper ? 16.w : 4.w),
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
            padding: EdgeInsets.only(top: 4.h, left: customWrapper ? 16.w : 4.w),
            child: CustemText(
              text: message.errorMessage!,
              size: 11,
              color: const Color(0xFFC62828),
            ),
          ),
        Gap(4.h),
        Padding(
          padding: EdgeInsets.only(left: customWrapper ? 16.w : 4.w),
          child: CustemText(
            text: timeText,
            size: 10,
            color: const Color(0xFF6B7A90),
          ),
        ),
      ],
    );
  }

  Widget _buildBlocks(List<ChatBlock> blocks) {
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) {
        if (block is ParagraphBlock) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              _cleanFormatting(block.text),
              style: TextStyle(
                color: _textColor(),
                fontSize: 15.sp,
                height: 1.4,
              ),
            ),
          );
        } else if (block is BulletBlock) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: block.items.map((item) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 4.h, left: 8.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•', style: TextStyle(color: _textColor(), fontSize: 15.sp)),
                      Gap(8.w),
                      Expanded(
                        child: Text(
                          _cleanFormatting(item),
                          style: TextStyle(
                            color: _textColor(),
                            fontSize: 15.sp,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        } else if (block is SpacerBlock) {
          return Gap(8.h);
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  String _cleanFormatting(String text) {
    return text.replaceAll(RegExp(r'\*\*'), '').replaceAll(RegExp(r'\*'), '');
  }
}
