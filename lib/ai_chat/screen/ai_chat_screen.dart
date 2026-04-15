import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:vitaguard_app/ai_chat/data/ai_chat_models.dart';
import 'package:vitaguard_app/ai_chat/ui/ai_chat_provider.dart';
import 'package:vitaguard_app/ai_chat/widget/ai_message_bubble.dart';
import 'package:vitaguard_app/components/custem_background.dart';
import 'package:vitaguard_app/components/message_input.dart';
import 'package:vitaguard_app/core/providers.dart';
import 'package:vitaguard_app/core/utils/simple_header.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  final AiChatProvider? provider;

  const AiChatScreen({super.key, this.provider});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  AiChatProvider get _provider => widget.provider ?? ref.read(aiChatProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.ensureConversation();
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final ok = await _provider.sendMessage(text);
    if (!ok && mounted) {
      _messageController.text = text;
      final error = _provider.error;
      if (error != null && error.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        final provider = _provider;
        final title = provider.conversation?.title ?? 'VitaGuard AI';

        return Scaffold(
          appBar: SimpleHeader(title: title),
          body: SafeArea(
            child: AppBackground(
              child: Column(
                children: [
                  if (provider.error != null)
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
                          provider.error!,
                          style: TextStyle(
                            color: const Color(0xFF8A5200),
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: _buildMessages(provider),
                  ),
                  MessageInput(
                    controller: _messageController,
                    onSend: _sendMessage,
                    enabled: !provider.isLoading && !provider.isSending,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessages(AiChatProvider provider) {
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
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFF51617A),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<List<AiMessage>>(
      stream: provider.messageStream,
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
          reverse: true,
          padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 16.h),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[messages.length - 1 - index];
            final previous = index < messages.length - 1
                ? messages[messages.length - 2 - index]
                : null;

            return AiMessageBubble(
              message: message,
              isPreviousSameSender: previous?.role == message.role,
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
