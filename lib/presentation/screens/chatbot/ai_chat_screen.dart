import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/core/feedback/clinical_feedback.dart';
import 'package:vitaguard_app/data/models/chatbot/ai_chat_models.dart';
import 'package:vitaguard_app/presentation/widgets/chatbot/ai_message_bubble.dart';
import 'package:intl/intl.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:vitaguard_app/presentation/screens/auth/sign_in_screen.dart';
import 'package:vitaguard_app/presentation/controllers/chatbot/ai_chat_provider.dart';
import '../../../core/utils/custem_background.dart';
import '../../../core/utils/message_input.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

  Future<void> _sendQuickReply(String suggestion) async {
    final text = suggestion.trim();
    if (text.isEmpty) return;
    debugPrint('[AI_CHAT_SCREEN] _sendQuickReply: "$text"');
    final ok = await ref
        .read(aiChatControllerProvider.notifier)
        .sendMessage(text);
    if (!ok && mounted) {
      debugPrint('[AI_CHAT_SCREEN] _sendQuickReply failed: "$text"');
    }
  }

  Future<void> _sendMessage() async {
    final rawText = _messageController.text;
    final text = rawText.trim();
    debugPrint(
      '[AI_CHAT_SCREEN] _sendMessage called. Raw: "$rawText" | Trimmed: "$text" | isEmpty: ${text.isEmpty}',
    );
    if (text.isEmpty) {
      debugPrint(
        '[AI_CHAT_SCREEN] _sendMessage rejected: text is empty after trim',
      );
      return;
    }

    _messageController.clear();
    debugPrint(
      '[AI_CHAT_SCREEN] Sending to provider: "$text" (length: ${text.length})',
    );
    final ok = await ref
        .read(aiChatControllerProvider.notifier)
        .sendMessage(text);
    debugPrint('[AI_CHAT_SCREEN] sendMessage result: $ok');
    if (!ok && mounted) {
      _messageController.text = text;
      debugPrint(
        '[AI_CHAT_SCREEN] sendMessage failed, restoring text to controller',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Consumer(
        builder: (context, ref, _) {
          final provider = ref.watch(aiChatControllerProvider);
          final title =
              ref.read(aiChatControllerProvider).conversation?.title ??
              'VitaGuard AI';
          final hasUser = SupabaseService.instance.currentSession?.user != null;

          final isLocked = !hasUser;

          return Scaffold(
            appBar: AppBar(
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  color: const Color(0xFF0D3B66),
                ),
              ),
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
                      ref
                          .read(aiChatControllerProvider.notifier)
                          .startNewChat();
                    },
                  ),
              ],
              bottom: isLocked
                  ? null
                  : TabBar(
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
                child: isLocked
                    ? _buildUnauthorizedOverlay()
                    : TabBarView(
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
            Icon(
              Icons.lock_outline,
              size: 80.r,
              color: const Color(0xFFC62828),
            ),
            Gap(20.h),
            Text(
              'Authentication Required',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D3B66),
              ),
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
                await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SignInScreen()));
                if (mounted &&
                    SupabaseService.instance.currentSession != null) {
                  ref
                      .read(aiChatControllerProvider.notifier)
                      .ensureConversation(forceRefresh: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A3FF),
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
              child: Text(
                'Log in now',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChatTab(AiChatState provider) {
    bool isHistorical = false;
    String displayDate = '';

    if (provider.conversation != null) {
      final localTime = provider.conversation!.createdAt.toLocal();
      final now = DateTime.now();
      isHistorical =
          localTime.year != now.year ||
          localTime.month != now.month ||
          localTime.day != now.day;
      if (isHistorical) {
        displayDate = DateFormat('MMMM d, yyyy').format(localTime);
      }
    }

    return Column(
      children: [
        if (provider.error != null)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: ClinicalFeedbackPanel(
              type: ClinicalPopupType.warning,
              title: 'VitaGuard AI Connection',
              message: ErrorMapper.mapForUser(
                provider.error!,
                const ClinicalErrorContext(area: ClinicalErrorArea.chatbot),
              ).message,
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
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF1B5E20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref
                        .read(aiChatControllerProvider.notifier)
                        .ensureConversation(forceRefresh: true);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: const Color(0xFFC8E6C9),
                  ),
                  child: Text(
                    'Return to Today',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
          ),

        Expanded(child: _buildMessages(provider)),
        _buildQuickRepliesSection(provider, isHistorical),
        if (provider.isSending)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 16.w),
            child: Row(
              children: [
                SizedBox(
                  width: 14.r,
                  height: 14.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00A3FF),
                  ),
                ),
              ],
            ),
          ),
        MessageInput(
          controller: _messageController,
          onSend: _sendMessage,
          enabled: !provider.isLoading && !provider.isSending,
        ),
      ],
    );
  }

  Widget _buildHistoryTab(AiChatState provider) {
    final errorStr = provider.error == null
        ? ''
        : ErrorMapper.mapForUser(
            provider.error!,
            const ClinicalErrorContext(area: ClinicalErrorArea.chatbot),
          ).message;
    if (errorStr.isNotEmpty && errorStr.toLowerCase().contains('logged in')) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<AiConversation>>(
      future: ref.read(aiChatControllerProvider.notifier).fetchUserHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00A3FF)),
          );
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

            final isCurrent = provider.conversation?.id == conversation.id;

            return InkWell(
              onTap: () {
                ref
                    .read(aiChatControllerProvider.notifier)
                    .ensureConversation(
                      conversationId: conversation.id,
                      forceRefresh: true,
                    );
                DefaultTabController.of(context).animateTo(0);
              },
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isCurrent ? const Color(0xFFE3EEF7) : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isCurrent
                        ? const Color(0xFF00A3FF)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
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
                      child: Icon(
                        Icons.history,
                        color: const Color(0xFF51617A),
                        size: 24.r,
                      ),
                    ),
                    Gap(16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D3B66),
                            ),
                          ),
                          Gap(4.h),
                          Text(
                            'Session started at $timeStr',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: const Color(0xFFCBD5E1),
                      size: 24.r,
                    ),
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
    if (provider.isLoading && provider.conversation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.conversation == null || provider.messageStream == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            'Open a conversation to ask about symptoms, reports, medications, or health guidance.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15.sp, color: const Color(0xFF51617A)),
          ),
        ),
      );
    }

    return StreamBuilder<List<AiMessage>>(
      stream: provider.messageStream,
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const <AiMessage>[];

        // Merge pending assistant message if no real assistant message exists yet
        final pending = provider.pendingAssistantMessage;
        var displayMessages = messages;
        if (pending != null) {
          final hasRealAssistant = displayMessages.any(
            (m) => m.role == AiMessageRole.assistant && !m.isPending,
          );
          if (!hasRealAssistant) {
            displayMessages = [...displayMessages, pending];
          }
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            displayMessages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (displayMessages.isEmpty) {
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

        // Clear pending when real assistant message arrives
        if (pending != null &&
            displayMessages.any(
              (m) => m.role == AiMessageRole.assistant && !m.isPending,
            )) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(aiChatControllerProvider.notifier).clearPendingMessage();
          });
        }

        return ListView.builder(
          key: const PageStorageKey('chat_list'),
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 16.h),
          reverse: true,
          itemCount: displayMessages.length + 1,
          itemBuilder: (context, index) {
            if (index == displayMessages.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
                child: Column(
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      color: const Color(0xFF003F6B),
                      size: 40.r,
                    ),
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

            final message = displayMessages[index];
            final nextIsSame =
                index + 1 < displayMessages.length &&
                displayMessages[index + 1].role == message.role;

            return AiMessageBubble(
              key: ValueKey(message.id),
              message: message,
              isPreviousSameSender: nextIsSame,
              isLastMessage: index == 0,
            );
          },
        );
      },
    );
  }

  Widget _buildQuickRepliesSection(AiChatState provider, bool isHistorical) {
    if (isHistorical) return const SizedBox.shrink();
    if (provider.conversation == null || provider.messageStream == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<AiMessage>>(
      stream: provider.messageStream,
      builder: (context, snapshot) {
        final messages = snapshot.data ?? [];
        List<String> suggestions = [];

        if (messages.isEmpty) {
          // If the conversation is brand new and has no messages, show default quick replies based on role
          switch (provider.conversation!.role) {
            case AiConversationRole.patient:
              suggestions = [
                'Check my latest vitals',
                'Report a new symptom',
                'Explain my health trends',
                'General health question',
              ];
              break;
            case AiConversationRole.companion:
              suggestions = [
                'How is the patient doing?',
                'Track patient vitals',
                'Log medication compliance',
                'Ask caregiving advice',
              ];
              break;
            case AiConversationRole.doctor:
              suggestions = [
                'Analyze patient vitals',
                'Draft clinical summary',
                'Review patient trends',
                'Clinical guidelines reference',
              ];
              break;
          }
        } else {
          final latestMessage = messages.first;

          if (latestMessage.role == AiMessageRole.assistant &&
              latestMessage.status == AiMessageStatus.complete &&
              latestMessage.quickReplies != null &&
              latestMessage.quickReplies!.isNotEmpty) {
            suggestions = latestMessage.quickReplies!;
          }
        }

        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

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
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF003F6B),
                    ),
                  ),
                  backgroundColor: const Color(0xFFF0F7FF),
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  side: const BorderSide(color: Color(0xFFB3E0FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  onPressed: provider.isSending
                      ? null
                      : () => _sendQuickReply(suggestion),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
