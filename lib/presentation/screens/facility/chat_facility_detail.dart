import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/core/chat/chat_repository.dart';
import 'package:vitaguard_app/core/utils/chat_header.dart';
import 'package:vitaguard_app/presentation/widgets/facility/message_facility_bubble.dart';
import 'package:vitaguard_app/data/models/message_model.dart';

import '../../../core/utils/custem_background.dart';
import '../../../core/utils/message_input.dart';

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
  late final Stream<List<ChatMessage>> _messageStream;
  final ChatRepository _repository = ChatRepository();

  bool _isDemoMode = true;
  // NOTE: For chat_facility_detail, the ListView renders messages[index], 
  // so index 0 is at the bottom (newest). The demo messages must be ordered newest-first.
  final List<ChatMessage> _demoMessages = [
    ChatMessage(
      id: '10',
      content: "Perfect, I will check it right now and adjust his medication if needed.",
      time: '2 minutes ago',
      sender: MessageSender.doctor,
      isRead: true,
    ),
    ChatMessage(
      id: '9',
      content: "Yes, doctor. The complete lab report has been uploaded and is now available for review in the portal.",
      time: '10 minutes ago',
      sender: MessageSender.user,
      isRead: true,
    ),
    ChatMessage(
      id: '8',
      content: "Thank you for the detailed update. Have the full PDF reports been uploaded to the system?",
      time: '20 minutes ago',
      sender: MessageSender.doctor,
      isRead: true,
    ),
    ChatMessage(
      id: '7',
      content: "WBC count is normal. No signs of severe infection.",
      time: '35 minutes ago',
      sender: MessageSender.user,
      isRead: true,
    ),
    ChatMessage(
      id: '6',
      content: "I see. And the complete blood count (CBC)?",
      time: '40 minutes ago',
      sender: MessageSender.doctor,
      isRead: true,
    ),
    ChatMessage(
      id: '5',
      content: "CRP is slightly elevated at 12 mg/L, which correlates with his recent fever.",
      time: '45 minutes ago',
      sender: MessageSender.user,
      isRead: true,
    ),
    ChatMessage(
      id: '4',
      content: "That's good. How about the inflammatory markers?",
      time: '50 minutes ago',
      sender: MessageSender.doctor,
      isRead: true,
    ),
    ChatMessage(
      id: '3',
      content: "The blood test analysis has been completed successfully. Most values are within the normal range.",
      time: '55 minutes ago',
      sender: MessageSender.user,
      isRead: true,
    ),
    ChatMessage(
      id: '2',
      content: "Hello. Yes, I’m following up on those lab results. Is there any anomaly?",
      time: '1 hour ago',
      sender: MessageSender.doctor,
      isRead: true,
    ),
    ChatMessage(
      id: '1',
      content: "Hello, this is VitaLab. We are contacting you regarding Hussain's recent blood test samples.",
      time: '2 hours ago',
      sender: MessageSender.user,
      isRead: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _messageStream = _repository.streamMessages(
      widget.chatId,
      otherSender: MessageSender.patient,
      ascending: false,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    if (_isDemoMode) {
      setState(() {
        _demoMessages.insert(0, ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: text,
          time: 'Just now',
          sender: MessageSender.user,
          isRead: true,
        ));
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _demoMessages.insert(0, ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: "We received your message. A lab technician will review it shortly.",
            time: 'Just now',
            sender: MessageSender.doctor,
            isRead: true,
          ));
        });
      });
    } else {
      try {
        await _repository.sendMessage(widget.chatId, text);
      } catch (e) {
        debugPrint('Error sending message: $e');
      }
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
              // Date header
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
                    'Monday',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ),
              ),

              // Messages
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: _messageStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final realMessages = snapshot.data ?? [];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _isDemoMode != realMessages.isEmpty) {
                        setState(() {
                          _isDemoMode = realMessages.isEmpty;
                        });
                      }
                    });

                    final messages = _isDemoMode ? _demoMessages : realMessages;

                    return ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isPreviousSameSender =
                            index < messages.length - 1 &&
                            messages[index + 1].sender == message.sender;

                        return MessageFacilityBubble(
                          message: message,
                          isPreviousSameSender: isPreviousSameSender,
                          drName: widget.chatName,
                          patientName: 'Facility Admin',
                        );
                      },
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
