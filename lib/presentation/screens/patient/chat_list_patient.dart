import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vitaguard_app/presentation/screens/chatbot/ai_chat_screen.dart';
import 'package:vitaguard_app/core/chat/chat_repository.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';
import 'package:vitaguard_app/data/models/message_model.dart';
import 'package:vitaguard_app/presentation/screens/patient/chat_patient_detail.dart';
import 'package:vitaguard_app/presentation/widgets/patient/home_search.dart';

import '../../../core/utils/chat_preview_card.dart';
import '../../../core/utils/custem_background.dart';
import '../../../core/utils/custem_text.dart';

class ChatListPatient extends StatefulWidget {
  final ChatRepository? repository;
  final Widget? aiChatScreen;

  const ChatListPatient({super.key, this.repository, this.aiChatScreen});

  @override
  State<ChatListPatient> createState() => _ChatListPatientState();
}

class _ChatListPatientState extends State<ChatListPatient> {
  late final ChatRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ChatRepository();
  }

  void _onBotTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => widget.aiChatScreen ?? const AiChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeader(title: "Message", automaticallyImplyLeading: false),
      body: SafeArea(
        child: Stack(
          children: [
            StreamBuilder<List<ChatPreview>>(
              stream: _repository.streamConversations(),
              builder: (context, snapshot) {
                final chats = snapshot.data ?? [];

                return AppBackground(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Gap(20.h),
                              HomeSearch(),
                              Gap(10.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8.r,
                                      height: 8.r,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00A3FF),
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
                              if (chats.isEmpty)
                                Padding(
                                  padding: EdgeInsets.all(24.r),
                                  child: Text(
                                    'No conversations yet.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14.sp,
                                    ),
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
                                            builder: (context) =>
                                                ChatPatientDetail(
                                                  chatName: chat.name,
                                                  chatId: chat.id,
                                                ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              SizedBox(height: 92.h),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            Positioned(
              right: 20.w,
              bottom: 20.h,
              child: Material(
                color: const Color(0xFF0F1828),
                borderRadius: BorderRadius.circular(16.r),
                child: InkWell(
                  onTap: _onBotTap,
                  borderRadius: BorderRadius.circular(16.r),
                  child: SizedBox(
                    width: 56.r,
                    height: 56.r,
                    child: Icon(
                      LucideIcons.bot,
                      color: const Color(0xFF4D7CFE),
                      size: 30.r,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
