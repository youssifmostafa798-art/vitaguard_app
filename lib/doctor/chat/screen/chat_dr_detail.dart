import 'package:flutter/material.dart';
import 'package:vitaguard_app/doctor/chat/widget/message_dr_bubble.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/chat/chat_repository.dart';
import 'package:vitaguard_app/core/chat_header.dart';
import 'package:vitaguard_app/components/message_input.dart';
import 'package:vitaguard_app/models/message_model.dart';

class ChatDrDetail extends StatefulWidget {
  final String chatName;
  final String chatId;

  const ChatDrDetail({super.key, required this.chatName, required this.chatId});

  @override
  State<ChatDrDetail> createState() => _ChatDrDetailState();
}

class _ChatDrDetailState extends State<ChatDrDetail> {
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
        child: AppBackground(
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
                    otherSender: MessageSender.patient,
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
                        final isPreviousSameSender = index < messages.length - 1 &&
                            messages[messages.length - 2 - index].sender ==
                                message.sender;

                        return MessageDrBubble(
                          message: message,
                          isPreviousSameSender: isPreviousSameSender,
                          drName: widget.chatName,
                        );
                      },
                    );
                  },
                ),
              ),
              MessageInput(
                controller: _messageController,
                onSend: _sendMessage,
              ),
            ],
          ),
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
