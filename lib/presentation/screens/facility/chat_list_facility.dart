import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vitaguard_app/presentation/widgets/custem_background.dart';
import 'package:vitaguard_app/presentation/screens/chatbot/ai_chat_screen.dart';
import 'package:vitaguard_app/core/utils/home_header.dart';
import 'package:vitaguard_app/presentation/screens/facility/chat_facility_detail.dart';
import 'package:vitaguard_app/presentation/widgets/custem_text.dart';
import 'package:vitaguard_app/presentation/widgets/chat_preview_card.dart';
import 'package:vitaguard_app/presentation/widgets/patient/home_search.dart';
import 'package:vitaguard_app/data/models/message_model.dart';
import 'package:vitaguard_app/presentation/screens/auth/role_screen.dart';
import 'package:vitaguard_app/core/chat/chat_repository.dart';
import 'package:vitaguard_app/presentation/controllers/auth/auth_provider.dart';

class ChatListFacility extends ConsumerStatefulWidget {
  final String name;
  final Widget? aiChatScreen;
  const ChatListFacility({super.key, required this.name,this.aiChatScreen});

  @override
  ConsumerState<ChatListFacility> createState() => _ChatListFacilityState();
}

class _ChatListFacilityState extends ConsumerState<ChatListFacility> {
  late final Stream<List<ChatPreview>> _chatStream;
  final ChatRepository _repository = ChatRepository();
  void _onBotTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => widget.aiChatScreen ?? const AiChatScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _chatStream = _repository.streamConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeHeader(
        name_: widget.name,
        onExit: () {
          ref.read(authControllerProvider.notifier).logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RoleScreen()),
            (route) => false,
          );
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            AppBackground(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          Gap(20.h),
                          HomeSearch(),
                          Gap(10.h),
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
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final chatsList = snapshot.data ?? [];

                              if (chatsList.isEmpty) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40.h),
                                  child: const Text(
                                    "No active conversations found.",
                                  ),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: chatsList.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final chat = chatsList[index];
                                  return ChatPreviewCard(
                                    chat: chat,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ChatFacilityDetail(
                                                chatName: chat.name,
                                                chatId: chat.id,
                                              ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                          SizedBox(height: 92.h),
                        ],
                      ),
                    );
                  },
                ),
              ),
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