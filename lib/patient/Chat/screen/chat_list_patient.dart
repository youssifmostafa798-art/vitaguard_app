import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/core/simple_header.dart';
import 'package:vitaguard_app/patient/chat/screen/chat_patient_detail.dart';
import 'package:vitaguard_app/models/chat_preview_card.dart';
import 'package:vitaguard_app/models/message_model.dart';

class ChatListPatient extends StatelessWidget {
  ChatListPatient({super.key});

  final List<ChatPreview> chats = [
    ChatPreview(
      id: '1',
      name: 'Dr Edam Ahmed',
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
      name: 'Dr Mohamed Ahmed',
      avatarInitials: 'MA',
      lastMessage:
          "Human, you're supposed to take your medication in the evening.",
      time: '2 min',
      sender: MessageSender.doctor,
      status: MessageStatus.active,
      unreadCount: 0,
    ),
    ChatPreview(
      id: '3',
      name: 'Dr Mohamed Ahmed',
      avatarInitials: 'MA',
      lastMessage:
          "Human, you're supposed to take two medications in the morning.",
      time: '1 min',
      sender: MessageSender.doctor,
      status: MessageStatus.active,
      unreadCount: 1,
    ),
    ChatPreview(
      id: '4',
      name: 'Medical Laboratory',
      avatarInitials: 'ML',
      lastMessage: "Your test results are ready now, sir.",
      time: '2 min',
      sender: MessageSender.facility,
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
      name: 'Dr Edam',
      avatarInitials: 'EA',
      lastMessage:
          "Human, you're supposed to take your medication in the morning.",
      time: '2 min',
      sender: MessageSender.doctor,
      status: MessageStatus.active,
      unreadCount: 1,
    ),
    ChatPreview(
      id: '7',
      name: 'Dr Ahmed',
      avatarInitials: 'MA',
      lastMessage:
          "Human, you're supposed to take your medication in the evening.",
      time: '2 min',
      sender: MessageSender.doctor,
      status: MessageStatus.active,
      unreadCount: 0,
    ),
    ChatPreview(
      id: '8',
      name: 'Dr Mohamed',
      avatarInitials: 'MA',
      lastMessage:
          "Human, you're supposed to take two medications in the morning.",
      time: '1 min',
      sender: MessageSender.doctor,
      status: MessageStatus.active,
      unreadCount: 1,
    ),
    ChatPreview(
      id: '9',
      name: 'Medical 5Laboratory',
      avatarInitials: 'ML',
      lastMessage: "Your test results are ready now, sir.",
      time: '2 min',
      sender: MessageSender.facility,
      status: MessageStatus.active,
    ),
    ChatPreview(
      id: '10',
      name: 'Dr Ali',
      avatarInitials: 'MA',
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
      appBar: SimpleHeader(title: "Message", automaticallyImplyLeading: false),
      body: SafeArea(
        child: AppBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Active chats section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(0xFF00A3FF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Gap(8),
                          CustemText(
                            text: "Active",
                            size: 18,
                            weight: FontWeight.w600,
                            color: Color(0xff003F6B),
                          ),
                        ],
                      ),
                    ),
                    // Chat list
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: chats.length,
                      separatorBuilder: (context, index) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return ChatPreviewCard(
                          chat: chat,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPatientDetail(
                                  chatName: chat.name,
                                  chatId: chat.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
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
