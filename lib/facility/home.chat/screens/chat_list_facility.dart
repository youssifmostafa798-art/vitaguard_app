import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/utils/home_header.dart';
import 'package:vitaguard_app/facility/home.chat/screens/chat_facility_detail.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/models/chat_preview_card.dart';
import 'package:vitaguard_app/patient/home/widget/home_search.dart';
import 'package:vitaguard_app/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//delete

class ChatListFacility extends StatefulWidget {
  final String name;
  const ChatListFacility({super.key, required this.name});

  @override
  State<ChatListFacility> createState() => _ChatListFacilityState();
}

class _ChatListFacilityState extends State<ChatListFacility> {
  late final Stream<List<ChatPreview>> _chatStream;

  @override
  void initState() {
    super.initState();
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      _chatStream = Supabase.instance.client
          .from('conversation_participants')
          .stream(primaryKey: ['conversation_id', 'user_id'])
          .eq('user_id', uid)
          .asyncMap((participants) async {
            List<ChatPreview> previews = [];
            for (final p in participants) {
              final convId = p['conversation_id'];
              
              final otherPart = await Supabase.instance.client
                  .from('conversation_participants')
                  .select('user_id')
                  .eq('conversation_id', convId)
                  .neq('user_id', uid)
                  .maybeSingle();

              String otherName = 'Patient';
              String initials = 'P';
              if (otherPart != null) {
                final profile = await Supabase.instance.client
                    .from('profiles')
                    .select('full_name, role')
                    .eq('id', otherPart['user_id'])
                    .maybeSingle();
                if (profile != null && profile['full_name'] != null) {
                  otherName = profile['full_name'];
                  initials = otherName.isNotEmpty ? otherName[0].toUpperCase() : 'P';
                }
              }

              final convDetail = await Supabase.instance.client
                  .from('conversations')
                  .select('last_message, last_message_at')
                  .eq('id', convId)
                  .maybeSingle();

              previews.add(ChatPreview(
                id: convId,
                name: otherName,
                avatarInitials: initials,
                lastMessage: convDetail?['last_message'] ?? 'Tap to view messages...',
                time: 'Now',
                sender: MessageSender.user,
                status: MessageStatus.active,
              ));
            }
            return previews;
          });
    } else {
      _chatStream = Stream.value([]);
    }
  }
  //delete
  final List<ChatPreview> chats = [
    ChatPreview(
      id: '1',
      name: 'Dr Ahmed Edam',
      avatarInitials: 'EA',
      lastMessage:
          "Human, you're supposed to take your medication in the morning.",
      time: '2 min',
      sender: MessageSender.doctor,
      status: MessageStatus.active,
      unreadCount: 1,
    ),
    ChatPreview(
      id: '2',
      name: 'Mohamed Ahmed',
      avatarInitials: 'MA',
      lastMessage:
          "Human, you're supposed to take your medication in the evening.",
      time: '2 min',
      sender: MessageSender.patient,
      status: MessageStatus.active,
      unreadCount: 0,
    ),
    ChatPreview(
      id: '3',
      name: 'Dr Ali Ahmed',
      avatarInitials: 'AA',
      lastMessage:
          "Human, you're supposed to take two medications in the morning.",
      time: '1 min',
      sender: MessageSender.doctor,
      status: MessageStatus.active,
      unreadCount: 1,
    ),
    ChatPreview(
      id: '4',
      name: 'Ebrahim Ayman',
      avatarInitials: 'EA',
      lastMessage: "Your test results are ready now, sir.",
      time: '2 min',
      sender: MessageSender.patient,
      status: MessageStatus.active,
    ),
    ChatPreview(
      id: '5',
      name: 'Dr Mohamed Ali',
      avatarInitials: 'MA',
      lastMessage:
          "Human, you're supposed to take your medication in the evening.",
      time: '2 min',
      sender: MessageSender.doctor,
      status: MessageStatus.active,
    ),
    ChatPreview(
      id: '6',
      name: 'Edam Adel',
      avatarInitials: 'EA',
      lastMessage:
          "Human, you're supposed to take your medication in the morning.",
      time: '2 min',
      sender: MessageSender.patient,
      status: MessageStatus.active,
      unreadCount: 1,
    ),
    ChatPreview(
      id: '7',
      name: 'Dr Ahmed Youssif',
      avatarInitials: 'MY',
      lastMessage:
          "Human, you're supposed to take your medication in the evening.",
      time: '2 min',
      sender: MessageSender.doctor,
      status: MessageStatus.active,
      unreadCount: 0,
    ),
    ChatPreview(
      id: '8',
      name: 'Dr Mohamed Emad',
      avatarInitials: 'ME',
      lastMessage:
          "Human, you're supposed to take two medications in the morning.",
      time: '1 min',
      sender: MessageSender.doctor,
      status: MessageStatus.active,
      unreadCount: 1,
    ),
    ChatPreview(
      id: '9',
      name: 'Shawki Ashraf',
      avatarInitials: 'SA',
      lastMessage: "Your test results are ready now, sir.",
      time: '2 min',
      sender: MessageSender.patient,
      status: MessageStatus.active,
    ),
    ChatPreview(
      id: '10',
      name: 'Dr Ali Amal',
      avatarInitials: 'AA',
      lastMessage:
          "Human, you're supposed to take your medication in the evening.",
      time: '2 min',
      sender: MessageSender.doctor,
      status: MessageStatus.active,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeHeader(
        name_: widget.name,
        onExit: () {
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: AppBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Gap(20.h),
                    const HomeSearch(),
                    // Active chats section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          Container(
                            width: 8.r,
                            height: 8.r,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A3FF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Gap(8.w),
                          CustemText(
                            text: "Active",
                            size: 18,
                            weight: FontWeight.w600,
                            color: const Color(0xff003F6B),
                          ),
                        ],
                      ),
                    ),
                    // Chat list
                    StreamBuilder<List<ChatPreview>>(
                      stream: _chatStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final chatsList = snapshot.data ?? [];
                        
                        if (chatsList.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.h),
                            child: const Text("No active conversations found."),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: chatsList.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final chat = chatsList[index];
                            return ChatPreviewCard(
                              chat: chat,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatFacilityDetail(
                                      chatName: chat.name,
                                      chatId: chat.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
