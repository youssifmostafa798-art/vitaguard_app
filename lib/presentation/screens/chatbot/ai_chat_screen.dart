import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/data/models/chatbot/ai_chat_models.dart';
import 'package:vitaguard_app/presentation/widgets/chatbot/ai_message_bubble.dart';
import 'package:vitaguard_app/presentation/widgets/custem_background.dart';
import 'package:vitaguard_app/presentation/widgets/message_input.dart';
import 'package:intl/intl.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:vitaguard_app/presentation/screens/auth/sign_in_screen.dart';
import 'package:vitaguard_app/presentation/controllers/chatbot/ai_chat_provider.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isHandlingQuickReply = false;



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiChatControllerProvider.notifier).ensureConversation();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final ok = await ref.read(aiChatControllerProvider.notifier).sendMessage(text);
    if (!ok && mounted) {
      _messageController.text = text;
      // Removed SnackBar to avoid duplicate error display.
      // Error is already shown in the persistent bubble above the message list.
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Consumer(
        builder: (context, ref, _) {
          final provider = ref.watch(aiChatControllerProvider);
          final title = ref.read(aiChatControllerProvider).conversation?.title ?? 'VitaGuard AI';
          final hasUser = SupabaseService.instance.currentSession?.user != null;

          // Full-screen lock ONLY if we have no local user session.
          final isLocked = !hasUser;

          return Scaffold(
            appBar: AppBar(
              title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: const Color(0xFF0D3B66))),
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Color(0xFF0D3B66)),
              actions: [
                if (!isLocked)
                  IconButton(
                    icon: const Icon(Icons.add_comment_rounded),
                    tooltip: 'Start New Chat',
                    onPressed: () {
                      ref.read(aiChatControllerProvider.notifier).startNewChat();
                    },
                  ),
              ],
              bottom: isLocked ? null : TabBar(
                labelColor: const Color(0xFF00A3FF),
                unselectedLabelColor: const Color(0xFF51617A),
                indicatorColor: const Color(0xFF00A3FF),
                tabs: const [
                  Tab(text: "Active Chat"),
                  Tab(text: "History"),
                ],
              ),
            ),
            body: SafeArea(
              child: AppBackground(
                child: isLocked ? _buildUnauthorizedOverlay() : TabBarView(
                  children: [
                    _buildActiveChatTab(provider),
                    _buildHistoryTab(provider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnauthorizedOverlay() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80.r, color: const Color(0xFFC62828)),
            Gap(20.h),
            Text(
              'Authentication Required',
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B66)),
            ),
            Gap(12.h),
            Text(
              'For your privacy and security, you must be logged in securely to interact with the VitaGuard AI and access your health data.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF51617A)),
            ),
            Gap(30.h),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
                // When returning from login, check if we have a session and refresh
                if (mounted && SupabaseService.instance.currentSession != null) {
                  ref.read(aiChatControllerProvider.notifier).ensureConversation(forceRefresh: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A3FF),
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
              ),
              child: Text('Log in now', style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChatTab(AiChatState provider) {
    bool isHistorical = false;
    String displayDate = '';

    if (ref.read(aiChatControllerProvider).conversation != null) {
      final localTime = ref.read(aiChatControllerProvider).conversation!.createdAt.toLocal();
      final now = DateTime.now();
      isHistorical = localTime.year != now.year || localTime.month != now.month || localTime.day != now.day;
      if (isHistorical) {
        displayDate = DateFormat('MMMM d, yyyy').format(localTime);
      }
    }

    return Column(
      children: [
        if (ref.read(aiChatControllerProvider).error?.toString() != null)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFFFD08A)),
              ),
              child: Text(
                ref.read(aiChatControllerProvider).error?.toString() ?? '',
                style: TextStyle(color: const Color(0xFF8A5200), fontSize: 13.sp),
              ),
            ),
          ),

        if (isHistorical)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            color: const Color(0xFFE8F5E9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Viewing Historical Session ($displayDate)',
                    style: TextStyle(fontSize: 12.sp, color: const Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(aiChatControllerProvider.notifier).ensureConversation(forceRefresh: true);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: const Color(0xFFC8E6C9),
                  ),
                  child: Text('Return to Today', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF1B5E20))),
                )
              ],
            ),
          ),

        Expanded(
          child: _buildMessages(provider),
        ),
        _buildQuickReplies(provider),
        if (ref.read(aiChatControllerProvider).isSending)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 16.w),
            child: Row(
              children: [
                SizedBox(
                  width: 14.r,
                  height: 14.r,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A3FF)),
                ),
              ],
            ),
          ),
        MessageInput(
          controller: _messageController,
          onSend: _sendMessage,
          enabled: !ref.read(aiChatControllerProvider).isLoading && !ref.read(aiChatControllerProvider).isSending,
        ),
      ],
    );
  }

  Widget _buildHistoryTab(AiChatState provider) {
    final errorStr = ref.read(aiChatControllerProvider).error?.toString() ?? '';
    if (errorStr.isNotEmpty && errorStr.toLowerCase().contains('logged in')) {
      return const SizedBox.shrink(); // Prevent fetching if fully unauthorized
    }

    return FutureBuilder<List<AiConversation>>(
      future: ref.read(aiChatControllerProvider.notifier).fetchUserHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00A3FF)));
        }

        if (snapshot.hasError) {
          return Center(child: Text("Unable to load history."));
        }

        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return Center(
            child: Text(
              "No past conversations found.",
              style: TextStyle(color: const Color(0xFF51617A), fontSize: 16.sp),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
          itemCount: history.length,
          separatorBuilder: (context, index) => Gap(12.h),
          itemBuilder: (context, index) {
            final conversation = history[index];
            final localTime = conversation.createdAt.toLocal();
            final dateStr = DateFormat('MMMM d, yyyy').format(localTime);
            final timeStr = DateFormat('h:mm a').format(localTime);

            final isCurrent = ref.read(aiChatControllerProvider).conversation?.id == conversation.id;

            return InkWell(
              onTap: () {
                ref.read(aiChatControllerProvider.notifier).ensureConversation(conversationId: conversation.id, forceRefresh: true);
                DefaultTabController.of(context).animateTo(0);
              },
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isCurrent ? const Color(0xFFE3EEF7) : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: isCurrent ? const Color(0xFF00A3FF) : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48.r,
                      height: 48.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.history, color: const Color(0xFF51617A), size: 24.r),
                    ),
                    Gap(16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B66)),
                          ),
                          Gap(4.h),
                          Text(
                            'Session started at $timeStr',
                            style: TextStyle(fontSize: 13.sp, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: const Color(0xFFCBD5E1), size: 24.r),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessages(AiChatState provider) {
    if (ref.read(aiChatControllerProvider).isLoading && ref.read(aiChatControllerProvider).conversation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ref.read(aiChatControllerProvider).conversation == null || ref.read(aiChatControllerProvider).messageStream == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            'Open a conversation to ask about symptoms, reports, medications, or health guidance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFF51617A),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<List<AiMessage>>(
      stream: ref.read(aiChatControllerProvider).messageStream,
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const <AiMessage>[];

        if (snapshot.connectionState == ConnectionState.waiting &&
            messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (messages.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                'Ask VitaGuard AI about symptoms, daily reports, medication reminders, or how to understand a health update.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFF51617A),
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          key: const PageStorageKey('chat_list'),
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 16.h),
          reverse: true, // Industry standard: newest at bottom
          itemCount: messages.length + 1,
          itemBuilder: (context, index) {
            // Header at the very top (index == length in a reversed list)
            if (index == messages.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
                child: Column(
                  children: [
                    Icon(Icons.health_and_safety, color: const Color(0xFF003F6B), size: 40.r),
                    Gap(10.h),
                    Text(
                      'Welcome to VitaGuard AI',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003F6B),
                      ),
                    ),
                    Gap(6.h),
                    Text(
                      'Disclaimer: I am an AI, not a doctor. This chat is not a substitute for professional medical advice, diagnosis, or treatment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF51617A),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Gap(20.h),
                  ],
                ),
              );
            }

            // Message logic
            final message = messages[index];
            // In a reversed list, the one "above" it has a HIGHER index (older)
            final nextIsSame = index + 1 < messages.length && messages[index + 1].role == message.role;

            return AiMessageBubble(
              key: ValueKey(message.id),
              message: message,
              isPreviousSameSender: nextIsSame,
            );
          },
        );
      },
    );
  }

  Widget _buildQuickReplies(AiChatState provider) {
    if (ref.read(aiChatControllerProvider).conversation == null || ref.read(aiChatControllerProvider).isLoading || ref.read(aiChatControllerProvider).isSending) return const SizedBox.shrink();

    final suggestions = [
      'Check my symptoms',
      'Daily wellness tip',
      'Track my mood',
      'Set a health goal',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: suggestions.asMap().entries.map((entry) {
          final isLast = entry.key == suggestions.length - 1;
          final suggestion = entry.value;

          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8.w),
            child: ActionChip(
              label: Text(
                suggestion,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: TextStyle(fontSize: 13.sp, color: const Color(0xFF003F6B)),
              ),
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 4.w), // Reduce internal padding if needed
              side: const BorderSide(color: Color(0xFF00A3FF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              onPressed: _isHandlingQuickReply || ref.read(aiChatControllerProvider).isSending
                  ? null
                  : () async {
                      setState(() => _isHandlingQuickReply = true);
                      _messageController.text = suggestion;
                      await _sendMessage();
                      if (mounted) {
                        setState(() => _isHandlingQuickReply = false);
                      }
                    },
            ),
          );
        }).toList(),
      ),
    );
  }
}
