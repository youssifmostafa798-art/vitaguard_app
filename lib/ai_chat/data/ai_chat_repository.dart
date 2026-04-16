import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vitaguard_app/ai_chat/data/ai_chat_models.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:vitaguard_app/core/utils/uuid.dart';

abstract class AiChatRepository {
  String? get currentUserIdOrNull;

  Future<AiConversation> ensureConversation();

  Stream<List<AiMessage>> streamMessages(String conversationId);

  Future<String> insertUserMessage(String conversationId, String content);

  Future<void> requestAssistantReply({
    required String conversationId,
    required String userMessageId,
  });
}

class SupabaseAiChatRepository implements AiChatRepository {
  final SupabaseService _supabase;

  SupabaseAiChatRepository({SupabaseService? supabase})
    : _supabase = supabase ?? SupabaseService.instance;

  SupabaseClient get _client => _supabase.client;

  @override
  String? get currentUserIdOrNull => _supabase.currentUidOrNull;

  String get _uid => _supabase.currentUid;

  @override
  Future<AiConversation> ensureConversation() async {
    final existing = await _client
        .from('ai_conversations')
        .select()
        .eq('owner_user_id', _uid)
        .limit(1);

    if (existing.isNotEmpty) {
      return AiConversation.fromMap(
        Map<String, dynamic>.from(existing.first as Map),
      );
    }

    final role = await _loadConversationRole();
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      final inserted = await _client
          .from('ai_conversations')
          .insert({
            'owner_user_id': _uid,
            'role': _roleToValue(role),
            'context_patient_id': await _resolveContextPatientId(role),
            'title': _defaultTitle(role),
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .limit(1);

      if (inserted.isEmpty) {
        throw StateError('Failed to create AI conversation.');
      }

      return AiConversation.fromMap(
        Map<String, dynamic>.from(inserted.first as Map),
      );
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;

      final rows = await _client
          .from('ai_conversations')
          .select()
          .eq('owner_user_id', _uid)
          .limit(1);

      if (rows.isEmpty) {
        throw StateError('Failed to load existing AI conversation.');
      }

      return AiConversation.fromMap(
        Map<String, dynamic>.from(rows.first as Map),
      );
    }
  }

  @override
  Stream<List<AiMessage>> streamMessages(String conversationId) {
    return _client
        .from('ai_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map(
          (rows) => rows
              .map(
                (row) =>
                    AiMessage.fromMap(Map<String, dynamic>.from(row as Map)),
              )
              .toList(),
        );
  }

  @override
  Future<String> insertUserMessage(
    String conversationId,
    String content,
  ) async {
    final messageId = Uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();

    await _client.from('ai_messages').insert({
      'id': messageId,
      'conversation_id': conversationId,
      'owner_user_id': _uid,
      'role': 'user',
      'content': content,
      'status': 'complete',
      'created_at': now,
      'updated_at': now,
    });

    return messageId;
  }

  @override
  Future<void> requestAssistantReply({
    required String conversationId,
    required String userMessageId,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw StateError('You must be logged in to chat with VitaGuard AI.');
    }

    final response = await _client.functions.invoke(
      'chatbot',
      body: {'conversationId': conversationId, 'userMessageId': userMessageId},
    );

    if (response.status != 202) {
      final message = _extractErrorMessage(response.data);
      throw StateError(
        message ?? 'The AI assistant could not start a reply right now.',
      );
    }
  }

  Future<AiConversationRole> _loadConversationRole() async {
    final rows = await _client
        .from('profiles')
        .select('role')
        .eq('id', _uid)
        .limit(1);

    if (rows.isEmpty) {
      throw StateError('Your profile could not be found.');
    }

    return aiConversationRoleFromString(rows.first['role']?.toString());
  }

  Future<String?> _resolveContextPatientId(AiConversationRole role) async {
    switch (role) {
      case AiConversationRole.patient:
        return _uid;
      case AiConversationRole.companion:
        final rows = await _client
            .from('companions')
            .select('linked_patient_id')
            .eq('id', _uid)
            .limit(1);

        if (rows.isEmpty) return null;
        return rows.first['linked_patient_id']?.toString();
      case AiConversationRole.doctor:
        return null;
    }
  }

  String _defaultTitle(AiConversationRole role) {
    switch (role) {
      case AiConversationRole.doctor:
        return 'VitaGuard Clinical AI';
      case AiConversationRole.companion:
      case AiConversationRole.patient:
        return 'VitaGuard AI';
    }
  }

  String _roleToValue(AiConversationRole role) {
    switch (role) {
      case AiConversationRole.companion:
        return 'companion';
      case AiConversationRole.doctor:
        return 'doctor';
      case AiConversationRole.patient:
        return 'patient';
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    }
    return null;
  }
}
