import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/core/chat/chat_repository.dart';
import 'package:vitaguard_app/core/utils/chat_header.dart';
import 'package:vitaguard_app/presentation/widgets/patient/message_patient_bubble.dart';
import 'package:vitaguard_app/data/models/message_model.dart';

import '../../../core/utils/custem_background.dart';
import '../../../core/utils/message_input.dart';

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

  bool _isDemoMode = true;
  final List<ChatMessage> _demoMessages = [
    ChatMessage(
      id: '1',
      content:
          "Hello Hussain. I noticed a breathing irregularity warning from your VitaGuard monitor earlier. Have you used your inhaler?",
      time: '1 hour ago',
      sender: MessageSender.doctor,
      isRead: true,
    ),
    ChatMessage(
      id: '2',
      content: "I used the inhaler 30 minutes ago.",
      time: '55 minutes ago',
      sender: MessageSender.user,
      isRead: true,
    ),
    ChatMessage(
      id: '3',
      content:
          "Good. The system shows your oxygen level is back to 98% which is normal.",
      time: '50 minutes ago',
      sender: MessageSender.doctor,
      isRead: true,
    ),
    ChatMessage(
      id: '4',
      content: "My breathing is better now, thank you.",
      time: '45 minutes ago',
      sender: MessageSender.user,
      isRead: true,
    ),
    ChatMessage(
      id: '5',
      content:
          "We received an alert from your device showing an elevated heart rate (110 BPM) for the last 15 minutes. Were you exercising?",
      time: '20 minutes ago',
      sender: MessageSender.doctor,
      isRead: true,
    ),
    ChatMessage(
      id: '6',
      content:
          "Yes, I was climbing the stairs. I stopped and took deep breaths.",
      time: '18 minutes ago',
      sender: MessageSender.user,
      isRead: true,
    ),
    ChatMessage(
      id: '7',
      content:
          "Your recent temperature log showed a slight fever (37.8°C). Take a paracetamol and drink plenty of water.",
      time: '15 minutes ago',
      sender: MessageSender.doctor,
      isRead: true,
    ),
    ChatMessage(
      id: '8',
      content: "Okay, I will take it right now.",
      time: '10 minutes ago',
      sender: MessageSender.user,
      isRead: true,
    ),
    ChatMessage(
      id: '9',
      content:
          "Also, please keep your VitaGuard wristband on while sleeping so we can track your oxygen level continuously.",
      time: '5 minutes ago',
      sender: MessageSender.doctor,
      isRead: true,
    ),
    ChatMessage(
      id: '10',
      content:
          "Yes, I understand. I will keep monitoring my heart rate and rest.",
      time: '2 minutes ago',
      sender: MessageSender.user,
      isRead: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    if (_isDemoMode) {
      setState(() {
        _demoMessages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: text,
            time: DateTime.now().toIso8601String(),
            sender: MessageSender.user,
            isRead: true,
          ),
        );
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _demoMessages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content:
                  "Please stay calm. I'm checking your readings now. If the pain increases, call emergency services.",
              time: DateTime.now().toIso8601String(),
              sender: MessageSender.doctor,
              isRead: true,
            ),
          );
        });
      });
    } else {
      await _repository.sendMessage(widget.chatId, text);
    }
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
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
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
                    final realMessages = snapshot.data ?? [];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _isDemoMode != realMessages.isEmpty) {
                        setState(() {
                          _isDemoMode = realMessages.isEmpty;
                        });
                      }
                    });

                    final messages = _isDemoMode ? _demoMessages : realMessages;
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
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      itemCount: messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return Gap(10.h);
                        }

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
              Gap(10.h),
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
