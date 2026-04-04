import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vitaguard_app/facility/home.chat/widget/message_facility_bubble.dart';
import 'package:vitaguard_app/core/chat_header.dart';
import 'package:vitaguard_app/components/message_input.dart';
import 'package:vitaguard_app/models/message_model.dart';

// change
class ChatFacilityDetail extends StatefulWidget {
  final String chatName;
  final String chatId;

  const ChatFacilityDetail({
    super.key,
    required this.chatName,
    required this.chatId,
  });

  @override
  State<ChatFacilityDetail> createState() => _ChatFacilityDetailState();
}

class _ChatFacilityDetailState extends State<ChatFacilityDetail> {
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
            "Hello, this is VitaLab. We are contacting you regarding the recent test samples.",
        time: '10:41',
        sender: MessageSender.user,
        isRead: true,
      ),
      ChatMessage(
        id: '2',
        content: "Hello. Yes, I’m following up on the patient’s lab results.",
        time: '10:44',
        sender: MessageSender.doctor,
        isRead: true,
      ),
      ChatMessage(
        id: '3',
        content:
            "The blood test analysis has been completed successfully. Most values are within the normal range",
        time: '10:47',
        sender: MessageSender.user,
        isRead: true,
      ),
      ChatMessage(
        id: '4',
        content:
            "Thank you for the update. Have the full reports been uploaded to the system?",
        time: '11:03',
        sender: MessageSender.doctor,
        isRead: true,
      ),
      ChatMessage(
        id: '5',
        content:
            "Yes, doctor. The complete lab report has been uploaded and is now available for review.",
        time: '12:13',
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
                        final message = _messages[_messages.length - 1 - index];
                        final isPreviousSameSender =
                            index < _messages.length - 1 &&
                            _messages[_messages.length - 2 - index].sender ==
                                message.sender;

                        return MessageFacilityBubble(
                          message: message,
                          isPreviousSameSender: isPreviousSameSender,
                          drName: widget.chatName,
                          patientName: widget.chatName,
                        );
                      },
                    ),
            ),

            // Message input
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
