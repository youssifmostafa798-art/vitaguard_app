import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/Facility/Home.Chat/screens/chat_facility_detail.dart';
import 'package:vitaguard_app/compenets/custem_background.dart';
import 'package:vitaguard_app/compenets/custem_text.dart';
import 'package:vitaguard_app/core/home_header.dart';
import 'package:vitaguard_app/Models/chat_preview_card.dart';
import 'package:vitaguard_app/patient/Home/widget/home_search.dart';
import '../../../Models/message_model.dart';
//delete

class ChatListFacility extends StatelessWidget {
  final String name;
  ChatListFacility({super.key, required this.name});
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
        name_: name,
        profileImage: const AssetImage("assets/PNG/youth_14.png"),
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
                    Gap(20),
                    HomeSearch(),
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
                                builder: (context) => ChatFacilityDetail(
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
