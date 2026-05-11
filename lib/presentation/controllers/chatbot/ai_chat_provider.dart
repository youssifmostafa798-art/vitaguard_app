import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vitaguard_app/data/models/chatbot/ai_chat_models.dart';
import 'package:vitaguard_app/data/repositories/chatbot/ai_chat_repository.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';

part 'ai_chat_provider.g.dart';

class AiChatState {
  final bool isLoading;
  final bool isSending;
  final String? error;
  final AiConversation? conversation;
  final Stream<List<AiMessage>>? messageStream;

  AiChatState({
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.conversation,
    this.messageStream,
  });

  AiChatState copyWith({
    bool? isLoading,
    bool? isSending,
    String? error,
    AiConversation? conversation,
    Stream<List<AiMessage>>? messageStream,
  }) {
    return AiChatState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
      conversation: conversation ?? this.conversation,
      messageStream: messageStream ?? this.messageStream,
    );
  }
}

@riverpod
class AiChatController extends _$AiChatController {
  AiChatRepository get _repository => ref.read(aiChatRepositoryProvider);
  DateTime _lastMessageSentAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _loadedUserId;

  @override
  AiChatState build() {
    // Keep alive for session: multi-step async ops set state between awaits.
    // Chat state must also survive screen navigation without losing conversation.
    ref.keepAlive();
    return AiChatState();
  }

  Future<List<AiConversation>> fetchUserHistory() async {
    if (_repository.currentUserIdOrNull == null) return [];
    return await _repository.fetchConversationHistory();
  }

  Future<void> ensureConversation({
    bool forceRefresh = false,
    String? conversationId,
  }) async {
    final currentUserId = _repository.currentUserIdOrNull;
    if (currentUserId == null) {
      state = state.copyWith(
        conversation: null,
        messageStream: null,
        error: 'You must be logged in to chat with VitaGuard AI.',
      );
      _loadedUserId = null;
      return;
    }

    final isTargetingDifferentConversation =
        conversationId != null && state.conversation?.id != conversationId;

    if (!forceRefresh &&
        !isTargetingDifferentConversation &&
        state.conversation != null &&
        _loadedUserId == currentUserId &&
        state.messageStream != null) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final conversation = await _repository.ensureConversation(conversationId);
      state = state.copyWith(
        isLoading: false,
        conversation: conversation,
        messageStream: _repository.streamMessages(conversation.id),
      );
      _loadedUserId = currentUserId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
    }
  }

  Future<void> startNewChat() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final conversation = await _repository.ensureConversation(null, true);
      state = state.copyWith(
        isLoading: false,
        conversation: conversation,
        messageStream: _repository.streamMessages(conversation.id),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.map(e));
    }
  }

  Future<bool> sendMessage(String content) async {
    final text = content.trim();
    if (text.isEmpty) {
      debugPrint(
        '[AI_CHAT] sendMessage rejected: empty or whitespace-only text',
      );
      return false;
    }
    if (state.isSending) {
      debugPrint('[AI_CHAT] sendMessage rejected: already sending');
      return false;
    }

    final now = DateTime.now();
    if (now.difference(_lastMessageSentAt).inMilliseconds < 1000) {
      debugPrint('[AI_CHAT] sendMessage rejected: rate limited');
      return false;
    }
    _lastMessageSentAt = now;

    // Capture text in local variable BEFORE clearing state / awaiting
    // so the UI edit changes can't interfere with the content
    final messageText = text;
    debugPrint(
      '[AI_CHAT] Sending message: "$messageText" (length: ${messageText.length})',
    );

    // Ensure we have a valid conversation, then re-read state to avoid stale closure
    await ensureConversation();
    final conversation = state.conversation;
    if (conversation == null) {
      debugPrint(
        '[AI_CHAT] sendMessage failed: no conversation after ensureConversation',
      );
      return false;
    }

    state = state.copyWith(isSending: true, error: null);

    try {
      final userMessageId = await _repository.insertUserMessage(
        conversation.id,
        messageText,
      );
      await _repository.requestAssistantReply(
        conversationId: conversation.id,
        userMessageId: userMessageId,
      );
      state = state.copyWith(isSending: false);
      debugPrint('[AI_CHAT] Message sent successfully');
      return true;
    } catch (e, stack) {
      state = state.copyWith(isSending: false, error: ErrorMapper.map(e));
      debugPrint('[AI_CHAT] sendMessage error: $e\n$stack');
      return false;
    }
  }

  void clearError() {
    if (state.error == null) return;
    state = state.copyWith(error: null);
  }

  void reset() {
    state = AiChatState();
    _loadedUserId = null;
  }
}
