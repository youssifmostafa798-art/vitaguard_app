import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vitaguard_app/doctor/chat/widget/message_dr_bubble.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/chat_header.dart';
import 'package:vitaguard_app/components/message_input.dart';
import '../../../models/message_model.dart';

class ChatDrDetail extends StatefulWidget {
  final String chatName;
  final String chatId;

  const ChatDrDetail({super.key, required this.chatName, required this.chatId});

  @override
  State<ChatDrDetail> createState() => _ChatDrDetailState();
}

class _ChatDrDetailState extends State<ChatDrDetail> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    // Simulate loading messages
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _messages.addAll(_getMockMessages());
      _isLoading = false;
    });
  }

  List<ChatMessage> _getMockMessages() {
    return [
      ChatMessage(
        id: '1',
        content:
            "Hello Mr., how are you today? I wanted to check on you after your last examination.",
        time: '10:35',
        sender: MessageSender.user,
        isRead: true,
      ),
      ChatMessage(
        id: '2',
        content:
            "Hello doctor, I’m feeling a bit better, but I still have mild chest pain.",
        time: '10:41',
        sender: MessageSender.patient,
        isRead: true,
      ),
      ChatMessage(
        id: '3',
        content:
            "I see. When does the pain usually occur? During physical activity or even at rest?",
        time: '10:44',
        sender: MessageSender.user,
        isRead: true,
      ),
      ChatMessage(
        id: '4',
        content:
            "It mostly happens when I climb stairs or walk for a long distance.",
        time: '10:47',
        sender: MessageSender.patient,
        isRead: true,
      ),
      ChatMessage(
        id: '5',
        content:
            "Understood. Have you been taking the medications I prescribed regularly?",
        time: '11:03',
        sender: MessageSender.user,
        isRead: true,
      ),
      ChatMessage(
        id: '6',
        content:
            "Yes, doctor, I’ve been taking them, but I missed one dose yesterday.",
        time: '12:13',
        sender: MessageSender.patient,
        isRead: true,
      ),
      ChatMessage(
        id: '7',
        content: "That’s okay, but please try not to miss any doses again.",
        time: '12:15',
        sender: MessageSender.user,
        isRead: true,
      ),
    ];
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().toString(),
      content: _messageController.text,
      time: DateFormat('HH:mm').format(DateTime.now()),
      sender: MessageSender.user,
      isRead: false,
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    // Simulate reply after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final reply = ChatMessage(
          id: DateTime.now().toString(),
          content: "Thank you for your message. I'll get back to you soon.",
          time: DateFormat('HH:mm').format(DateTime.now()),
          sender: MessageSender.doctor,
          isRead: false,
        );
        setState(() => _messages.add(reply));
      }
    });
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
              // Date header
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
                    'Monday',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),

              // Messages
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              _messages[_messages.length - 1 - index];
                          final isPreviousSameSender =
                              index < _messages.length - 1 &&
                              _messages[_messages.length - 2 - index].sender ==
                                  message.sender;

                          return MessageDrBubble(
                            message: message,
                            isPreviousSameSender: isPreviousSameSender,
                            drName: widget.chatName,
                          );
                        },
                      ),
              ),

              // Message input
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



