import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/core/utils/home_header.dart';
import 'package:vitaguard_app/facility/home.chat/screens/chat_facility_detail.dart';
import 'package:vitaguard_app/components/custem_text.dart';
import 'package:vitaguard_app/models/chat_preview_card.dart';
import 'package:vitaguard_app/patient/home/widget/home_search.dart';
import 'package:vitaguard_app/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/auth/ui/screens/role_screen.dart';
import 'package:vitaguard_app/core/providers.dart';

class ChatListFacility extends ConsumerStatefulWidget {
  final String name;
  const ChatListFacility({super.key, required this.name});

  @override
  ConsumerState<ChatListFacility> createState() => _ChatListFacilityState();
}

class _ChatListFacilityState extends ConsumerState<ChatListFacility> {
  late final Stream<List<ChatPreview>> _chatStream;
  void _onBotTap() {}

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
                  initials = otherName.isNotEmpty
                      ? otherName[0].toUpperCase()
                      : 'P';
                }
              }

              final convDetail = await Supabase.instance.client
                  .from('conversations')
                  .select('last_message, last_message_at')
                  .eq('id', convId)
                  .maybeSingle();

              previews.add(
                ChatPreview(
                  id: convId,
                  name: otherName,
                  avatarInitials: initials,
                  lastMessage:
                      convDetail?['last_message'] ?? 'Tap to view messages...',
                  time: 'Now',
                  sender: MessageSender.user,
                  status: MessageStatus.active,
                ),
              );
            }
            return previews;
          });
    } else {
      _chatStream = Stream.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeHeader(
        name_: widget.name,
        onExit: () {
          ref.read(authProvider).logout();
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
