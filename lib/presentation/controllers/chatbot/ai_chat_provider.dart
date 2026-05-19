import 'dart:developer' as dev;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vitaguard_app/data/models/chatbot/ai_chat_models.dart';
import 'package:vitaguard_app/data/repositories/chatbot/ai_chat_repository.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';
import 'package:vitaguard_app/features/chatbot/data/ai_response_sanitizer.dart';
import 'package:vitaguard_app/features/chatbot/domain/ai_content_normalizer.dart';
import 'package:vitaguard_app/features/chatbot/domain/ai_intent_classifier.dart';
import 'package:vitaguard_app/features/chatbot/domain/models/chat_message_model.dart';

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

  // Cache for parsed messages to support memoized UI rendering
  final Map<String, ChatMessageModel> _parsedCache = {};

  @override
  AiChatState build() {
    // Keep alive for session: multi-step async ops set state between awaits.
    // Chat state must also survive screen navigation without losing conversation.
    ref.keepAlive();
    return AiChatState();
  }

  /// Returns a cached [ChatMessageModel] to prevent UI stuttering.
  /// If the message is currently streaming, parses directly without caching.
  ChatMessageModel getParsedMessage(AiMessage message) {
    if (message.isUser) {
      return ChatMessageModel(
        text: message.content,
        intent: MessageIntent.normal,
        blocks: [],
        isValid: true,
      );
    }

    if (message.isStreaming) {
      return _parseAiMessage(message);
    }

    if (_parsedCache.containsKey(message.id)) {
      final cached = _parsedCache[message.id]!;
      // Simple invalidation check if content differs somehow
      if (cached.text == message.content || cached.text == AiResponseSanitizer.sanitize(message.content).text) {
        return cached;
      }
    }

    final parsed = _parseAiMessage(message);
    _parsedCache[message.id] = parsed;
    return parsed;
  }

  ChatMessageModel _parseAiMessage(AiMessage message) {
    final sanitized = AiResponseSanitizer.sanitize(message.content);
    if (!sanitized.isValid) {
      return const ChatMessageModel(
        text: '',
        intent: MessageIntent.normal,
        blocks: [],
        isValid: false,
      );
    }

    final intent = AiIntentClassifier.classify(sanitized.text);
    final blocks = AiContentNormalizer.normalize(sanitized.text);

    return ChatMessageModel(
      text: sanitized.text,
      intent: intent,
      blocks: blocks,
      isValid: true,
    );
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
      _parsedCache.clear();
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
      if (isTargetingDifferentConversation) _parsedCache.clear();
      
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
      _parsedCache.clear();
      
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
      dev.log('[AI_CHAT] sendMessage rejected: empty or whitespace-only text');
      return false;
    }
    if (state.isSending) {
      dev.log('[AI_CHAT] sendMessage rejected: already sending');
      return false;
    }

    final now = DateTime.now();
    if (now.difference(_lastMessageSentAt).inMilliseconds < 1000) {
      dev.log('[AI_CHAT] sendMessage rejected: rate limited');
      return false;
    }
    _lastMessageSentAt = now;

    // Capture text in local variable BEFORE clearing state / awaiting
    // so the UI edit changes can't interfere with the content
    final messageText = text;
    dev.log(
      '[AI_CHAT] Sending message: "$messageText" (length: ${messageText.length})',
    );

    // Ensure we have a valid conversation, then re-read state to avoid stale closure
    await ensureConversation();
    final conversation = state.conversation;
    if (conversation == null) {
      dev.log(
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
      dev.log('[AI_CHAT] Message sent successfully');
      return true;
    } catch (e, stack) {
      state = state.copyWith(isSending: false, error: ErrorMapper.map(e));
      dev.log('[AI_CHAT] sendMessage error: $e\n$stack');
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
    _parsedCache.clear();
  }
}
