import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/utils/chat_header.dart';
import 'package:vitaguard_app/facility/home.chat/widget/message_facility_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/components/message_input.dart';
import 'package:vitaguard_app/models/message_model.dart';
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
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _messageStream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.chatId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) {
              return ChatMessage(
                id: json['id'],
                content: json['content'] ?? '',
                time: json['created_at'] != null 
                    ? DateFormat('HH:mm').format(DateTime.parse(json['created_at']).toLocal())
                    : 'Now',
                sender: json['sender_id'] == _supabase.auth.currentUser?.id
                    ? MessageSender.user
                    : MessageSender.doctor,
                isRead: json['is_read'] ?? false,
              );
            }).toList());
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    
    try {
      await _supabase.from('messages').insert({
        'conversation_id': widget.chatId,
        'sender_id': uid,
        'content': text,
      });

      // Also quickly update the conversation last read / last message
      await _supabase.from('conversations').update({
        'last_message': text,
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.chatId);
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
