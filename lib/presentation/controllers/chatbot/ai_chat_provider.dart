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
    return AiChatState();
  }

  Future<List<AiConversation>> fetchUserHistory() async {
    if (_repository.currentUserIdOrNull == null) return [];
    return await _repository.fetchConversationHistory();
  }

  Future<void> ensureConversation({bool forceRefresh = false, String? conversationId}) async {
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

    final isTargetingDifferentConversation = conversationId != null && state.conversation?.id != conversationId;

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
    if (text.isEmpty || state.isSending) return false;

    final now = DateTime.now();
    if (now.difference(_lastMessageSentAt).inMilliseconds < 1000) {
       return false;
    }
    _lastMessageSentAt = now;

    await ensureConversation();
    if (state.conversation == null) return false;

    state = state.copyWith(isSending: true, error: null);

    try {
      final userMessageId = await _repository.insertUserMessage(
        state.conversation!.id,
        text,
      );
      await _repository.requestAssistantReply(
        conversationId: state.conversation!.id,
        userMessageId: userMessageId,
      );
      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSending: false, error: ErrorMapper.map(e));
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