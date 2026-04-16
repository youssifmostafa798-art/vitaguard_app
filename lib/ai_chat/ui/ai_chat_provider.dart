import 'package:flutter/material.dart';

import 'package:vitaguard_app/ai_chat/data/ai_chat_models.dart';
import 'package:vitaguard_app/ai_chat/data/ai_chat_repository.dart';
import 'package:vitaguard_app/core/errors/error_mapper.dart';

class AiChatProvider with ChangeNotifier {
  final AiChatRepository _repository;

  AiChatProvider({AiChatRepository? repository})
      : _repository = repository ?? SupabaseAiChatRepository();

  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  AiConversation? _conversation;
  Stream<List<AiMessage>>? _messageStream;
  String? _loadedUserId;

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  AiConversation? get conversation => _conversation;
  Stream<List<AiMessage>>? get messageStream => _messageStream;

  Future<List<AiConversation>> fetchUserHistory() async {
    if (_repository.currentUserIdOrNull == null) return [];
    return await _repository.fetchConversationHistory();
  }

  Future<void> ensureConversation({bool forceRefresh = false, String? conversationId}) async {
    final currentUserId = _repository.currentUserIdOrNull;
    if (currentUserId == null) {
      _conversation = null;
      _messageStream = null;
      _loadedUserId = null;
      _error = 'You must be logged in to chat with VitaGuard AI.';
      notifyListeners();
      return;
    }

    final isTargetingDifferentConversation = conversationId != null && _conversation?.id != conversationId;

    if (!forceRefresh &&
        !isTargetingDifferentConversation &&
        _conversation != null &&
        _loadedUserId == currentUserId &&
        _messageStream != null) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversation = await _repository.ensureConversation(conversationId);
      _conversation = conversation;
      _messageStream = _repository.streamMessages(conversation.id);
      _loadedUserId = currentUserId;
    } catch (e) {
      _error = ErrorMapper.map(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String content) async {
    final text = content.trim();
    if (text.isEmpty || _isSending) return false;

    await ensureConversation();
    final conversation = _conversation;
    if (conversation == null) {
      return false;
    }

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final userMessageId = await _repository.insertUserMessage(
        conversation.id,
        text,
      );
      await _repository.requestAssistantReply(
        conversationId: conversation.id,
        userMessageId: userMessageId,
      );
      return true;
    } catch (e) {
      _error = ErrorMapper.map(e);
      notifyListeners();
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void reset() {
    _isLoading = false;
    _isSending = false;
    _error = null;
    _conversation = null;
    _messageStream = null;
    _loadedUserId = null;
    notifyListeners();
  }
}
