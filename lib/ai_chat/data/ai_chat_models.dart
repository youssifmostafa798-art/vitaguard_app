enum AiConversationRole { patient, companion, doctor }

enum AiMessageRole { user, assistant, system }

enum AiMessageStatus { streaming, complete, error }

class AiConversation {
  final String id;
  final String ownerUserId;
  final AiConversationRole role;
  final String? contextPatientId;
  final String title;
  final String? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiConversation({
    required this.id,
    required this.ownerUserId,
    required this.role,
    required this.contextPatientId,
    required this.title,
    required this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiConversation.fromMap(Map<String, dynamic> map) {
    return AiConversation(
      id: map['id']?.toString() ?? '',
      ownerUserId: map['owner_user_id']?.toString() ?? '',
      role: aiConversationRoleFromString(map['role']?.toString()),
      contextPatientId: map['context_patient_id']?.toString(),
      title: map['title']?.toString() ?? 'VitaGuard AI',
      lastMessage: map['last_message']?.toString(),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }
}

class AiMessage {
  final String id;
  final String conversationId;
  final String ownerUserId;
  final AiMessageRole role;
  final String content;
  final AiMessageStatus status;
  final String? provider;
  final String? model;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiMessage({
    required this.id,
    required this.conversationId,
    required this.ownerUserId,
    required this.role,
    required this.content,
    required this.status,
    required this.provider,
    required this.model,
    required this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isUser => role == AiMessageRole.user;
  bool get isStreaming => status == AiMessageStatus.streaming;
  bool get isError => status == AiMessageStatus.error;

  factory AiMessage.fromMap(Map<String, dynamic> map) {
    return AiMessage(
      id: map['id']?.toString() ?? '',
      conversationId: map['conversation_id']?.toString() ?? '',
      ownerUserId: map['owner_user_id']?.toString() ?? '',
      role: aiMessageRoleFromString(map['role']?.toString()),
      content: map['content']?.toString() ?? '',
      status: aiMessageStatusFromString(map['status']?.toString()),
      provider: map['provider']?.toString(),
      model: map['model']?.toString(),
      errorMessage: map['error_message']?.toString(),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }
}

AiConversationRole aiConversationRoleFromString(String? value) {
  switch (value) {
    case 'companion':
      return AiConversationRole.companion;
    case 'doctor':
      return AiConversationRole.doctor;
    case 'patient':
    default:
      return AiConversationRole.patient;
  }
}

AiMessageRole aiMessageRoleFromString(String? value) {
  switch (value) {
    case 'assistant':
      return AiMessageRole.assistant;
    case 'system':
      return AiMessageRole.system;
    case 'user':
    default:
      return AiMessageRole.user;
  }
}

AiMessageStatus aiMessageStatusFromString(String? value) {
  switch (value) {
    case 'streaming':
      return AiMessageStatus.streaming;
    case 'error':
      return AiMessageStatus.error;
    case 'complete':
    default:
      return AiMessageStatus.complete;
  }
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value == null) return DateTime.now();
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}
