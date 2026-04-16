import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:vitaguard_app/ai_chat/data/ai_chat_models.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:vitaguard_app/core/utils/uuid.dart';

abstract class AiChatRepository {
  String? get currentUserIdOrNull;

  Future<AiConversation> ensureConversation([String? conversationId]);
  
  Future<List<AiConversation>> fetchConversationHistory();

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
  Future<List<AiConversation>> fetchConversationHistory() async {
    final rows = await _client
        .from('ai_conversations')
        .select()
        .eq('owner_user_id', _uid)
        .order('created_at', ascending: false);

    return rows.map((row) => AiConversation.fromMap(Map<String, dynamic>.from(row as Map))).toList();
  }

  @override
  Future<AiConversation> ensureConversation([String? conversationId]) async {
    if (conversationId != null) {
      final existing = await _client
          .from('ai_conversations')
          .select()
          .eq('owner_user_id', _uid)
          .eq('id', conversationId)
          .limit(1);
          
      if (existing.isNotEmpty) {
        return AiConversation.fromMap(
          Map<String, dynamic>.from(existing.first as Map),
        );
      }
      throw StateError('Requested conversation not found.');
    }

    final nowDateTime = DateTime.now();
    final todayStart = DateTime.utc(nowDateTime.year, nowDateTime.month, nowDateTime.day).toIso8601String();

    final existing = await _client
        .from('ai_conversations')
        .select()
        .eq('owner_user_id', _uid)
        .gte('created_at', todayStart)
        .order('created_at', ascending: false)
        .limit(1);

    if (existing.isNotEmpty) {
      return AiConversation.fromMap(
        Map<String, dynamic>.from(existing.first as Map),
      );
    }

    final role = await _loadConversationRole();
    final now = DateTime.now().toUtc().toIso8601String();

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
    // Force a session refresh to prevent 401s from stale tokens
    try {
      await _client.auth.refreshSession();
    } catch (_) {
      // If refresh fails, invoke will naturally fail with 401 anyway
    }

    final response = await _client.functions.invoke(
      'chatbot',
      body: {'conversationId': conversationId, 'userMessageId': userMessageId},
    );

    if (response.status != 202) {
      final message = _extractErrorMessage(response);
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

  String? _extractErrorMessage(dynamic error) {
    if (error is FunctionException) {
      final msg = error.reasonPhrase ?? 'Function error (${error.status}).';
      // If we have a status 401, it's definitely an auth/session issue
      if (error.status == 401) {
        return 'Session expired or unauthorized. Please log in again to continue.';
      }
      // If we have a status 400, try to return a more helpful message
      if (error.status == 400) {
        return 'Server error: $msg';
      }
      return msg;
    }
    return null;
  }
}
