import 'package:flutter/material.dart';
import 'package:vitaguard_app/core/chat/chat_repository.dart';
import 'package:vitaguard_app/core/chat_header.dart';
import 'package:vitaguard_app/patient/chat/widget/message_patient_bubble.dart';
import 'package:vitaguard_app/components/message_input.dart';
import 'package:vitaguard_app/models/message_model.dart';

class ChatPatientDetail extends StatefulWidget {
  final String chatName;
  final String chatId;

  const ChatPatientDetail({
    super.key,
    required this.chatName,
    required this.chatId,
  });

  @override
  State<ChatPatientDetail> createState() => _ChatPatientDetailState();
}

class _ChatPatientDetailState extends State<ChatPatientDetail> {
  final TextEditingController _messageController = TextEditingController();
  final ChatRepository _repository = ChatRepository();

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _repository.sendMessage(widget.chatId, text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatHeader(
        namee: widget.chatName,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _repository.streamMessages(
                  widget.chatId,
                  otherSender: MessageSender.doctor,
                ),
                builder: (context, snapshot) {
                  final messages = snapshot.data ?? [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final isPreviousSameSender =
                          index < messages.length - 1 &&
                          messages[messages.length - 2 - index].sender ==
                              message.sender;

                      return MessagePatientBubble(
                        message: message,
                        isPreviousSameSender: isPreviousSameSender,
                        doctorName: widget.chatName,
                        labName: widget.chatName,
                      );
                    },
                  );
                },
              ),
            ),
            MessageInput(controller: _messageController, onSend: _sendMessage),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
