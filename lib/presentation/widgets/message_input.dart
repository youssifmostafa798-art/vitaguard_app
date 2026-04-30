import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.grey.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              decoration: InputDecoration(
                hintText: enabled ? "type a message..." : "Chat ended",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              maxLines: null,
            ),
          ),
          Gap(8.w),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              final isTyping = value.text.trim().isNotEmpty;
              return CircleAvatar(
                radius: 24.r,
                backgroundColor: enabled ? const Color(0xFF00A3FF) : Colors.grey,
                child: IconButton(
                  icon: Icon(
                    isTyping ? Icons.send : Icons.mic,
                    color: Colors.white,
                    size: 22.r,
                  ),
                  onPressed: enabled
                      ? (isTyping
                          ? onSend
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Voice input coming soon!')),
                              );
                            })
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
