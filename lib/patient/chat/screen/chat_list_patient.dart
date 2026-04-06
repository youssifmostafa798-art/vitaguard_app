import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/core/chat/chat_repository.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/models/chat_preview_card.dart';
import 'package:vitaguard_app/models/message_model.dart';
import 'package:vitaguard_app/patient/chat/screen/chat_patient_detail.dart';

class ChatListPatient extends StatefulWidget {
  const ChatListPatient({super.key});

  @override
  State<ChatListPatient> createState() => _ChatListPatientState();
}

class _ChatListPatientState extends State<ChatListPatient> {
  final ChatRepository _repository = ChatRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeader(title: "Message", automaticallyImplyLeading: false),
      body: SafeArea(
        child: StreamBuilder<List<ChatPreview>>(
          stream: _repository.streamConversations(),
          builder: (context, snapshot) {
            final chats = snapshot.data ?? [];

            return AppBackground(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00A3FF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Gap(8),
                              CustemText(
                                text: "Active",
                                size: 18,
                                weight: FontWeight.w600,
                                color: const Color(0xff003F6B),
                              ),
                            ],
                          ),
                        ),
                        if (chats.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No conversations yet.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: chats.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
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
            );
          },
        ),
      ),
    );
  }
}
