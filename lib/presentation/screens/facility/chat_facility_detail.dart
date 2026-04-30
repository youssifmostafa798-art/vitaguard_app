import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/presentation/widgets/custem_background.dart';
import 'package:vitaguard_app/core/chat/chat_repository.dart';
import 'package:vitaguard_app/core/utils/chat_header.dart';
import 'package:vitaguard_app/presentation/widgets/facility/message_facility_bubble.dart';
import 'package:vitaguard_app/presentation/widgets/message_input.dart';
import 'package:vitaguard_app/data/models/message_model.dart';

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

    try {
      await _repository.sendMessage(widget.chatId, text);
    } catch (e) {
      debugPrint('Error sending message: $e');
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

                    final messages = snapshot.data ?? [];

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
                  }
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
