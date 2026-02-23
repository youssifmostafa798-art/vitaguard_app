import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/compenets/custem_text.dart';
import '../../../Models/message_model.dart';

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
        left: isUser ? 50 : 16,
        right: isUser ? 16 : 50,
        top: isPreviousSameSender ? 4 : 16,
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
              radius: 16,
              backgroundColor: senderColor,
              child: CustemText(
                text: senderInitial,
                size: 12,
                color: Colors.white,
                weight: FontWeight.w600,
              ),
            ),
          if (!isUser && !isPreviousSameSender) const Gap(8),

          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF00A3FF) : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show sender name for first message from doctor/lab
                  if (!isUser && !isPreviousSameSender)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
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

                  const Gap(4),

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
                        const Gap(4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
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
