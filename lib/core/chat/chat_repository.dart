import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitaguard_app/core/supabase/supabase_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vitaguard_app/data/models/message_model.dart';

part 'chat_repository.g.dart';

@riverpod
ChatRepository chatRepository(Ref ref) {
  return ChatRepository(supabase: ref.watch(supabaseServiceProvider));
}

class ChatRepository {
  ChatRepository({SupabaseService? supabase})
    : _supabase = supabase ?? SupabaseService.instance;

  final SupabaseService _supabase;

  SupabaseClient get _client => _supabase.client;
  String get _uid => _supabase.currentUid;

  Stream<List<ChatMessage>> streamMessages(
    String conversationId, {
    required MessageSender otherSender,
    bool ascending = true,
  }) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: ascending)
        .map((rows) {
          return rows.map((row) {
            final senderId = row['sender_id'] as String?;
            final createdAt = _parseDate(row['created_at']);
            return ChatMessage(
              id: row['id']?.toString() ?? '',
              content: row['content']?.toString() ?? '',
              time: DateFormat('HH:mm').format(createdAt),
              sender: senderId == _uid ? MessageSender.user : otherSender,
              isRead: row['is_read'] == true,
            );
          }).toList();
        });
  }

  Future<void> sendMessage(String conversationId, String content) async {
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': _uid,
      'content': content,
      'is_read': false,
    });

    await _client
        .from('conversations')
        .update({
          'last_message': content,
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);
  }

  Stream<List<ChatPreview>> streamConversations() async* {
    final stream = _client
        .from('conversation_participants')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('user_id', _uid);

    await for (final rows in stream) {
      final ids = rows.map((row) => row['conversation_id'] as String).toList();
      yield await _loadPreviews(ids);
    }
  }

  Future<List<ChatPreview>> getConversations() async {
    final rows = await _client
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', _uid);

    final ids = rows.map((row) => row['conversation_id'] as String).toList();

    return _loadPreviews(ids);
  }

  Future<List<ChatPreview>> _loadPreviews(List<String> conversationIds) async {
    if (conversationIds.isEmpty) return [];

    final conversations = await _client
        .from('conversations')
        .select()
        .inFilter('id', conversationIds);

    final participants = await _client
        .from('conversation_participants')
        .select('conversation_id, user_id, profiles(name, role)')
        .inFilter('conversation_id', conversationIds)
        .neq('user_id', _uid);

    final convMap = <String, Map<String, dynamic>>{};
    for (final row in conversations) {
      convMap[row['id'] as String] = Map<String, dynamic>.from(row as Map);
    }

    final previews = <ChatPreview>[];
    for (final row in participants) {
      final data = Map<String, dynamic>.from(row as Map);
      final convId = data['conversation_id'] as String;
      final profile = data['profiles'] as Map?;
      final name = profile?['name']?.toString() ?? 'Unknown';
      final role = profile?['role']?.toString();
      final sender = _senderFromRole(role);
      final conv = convMap[convId];
      final lastMessage = conv?['last_message']?.toString() ?? '';
      final lastAt = _parseDate(conv?['last_message_at']);

      previews.add(
        ChatPreview(
          id: convId,
          name: name,
          avatarInitials: name.isNotEmpty ? name[0].toUpperCase() : 'U',
          lastMessage: lastMessage,
          time: lastMessage.isNotEmpty
              ? DateFormat('HH:mm').format(lastAt)
              : '',
          sender: sender,
          status: MessageStatus.active,
        ),
      );
    }

    return previews;
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  MessageSender _senderFromRole(String? role) {
    switch (role) {
      case 'doctor':
        return MessageSender.doctor;
      case 'facility':
        return MessageSender.facility;
      case 'companion':
        return MessageSender.companion;
      case 'patient':
      default:
        return MessageSender.patient;
    }
  }
}