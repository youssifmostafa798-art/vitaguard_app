enum MessageSender { doctor, facility, patient, companion, user }

enum MessageStatus { active, pending }

class ChatPreview {
  final String id;
  final String name;
  final String avatarInitials;
  final String lastMessage;
  final String time;
  final MessageSender sender;
  final MessageStatus status;
  final int unreadCount;

  ChatPreview({
    required this.id,
    required this.name,
    required this.avatarInitials,
    required this.lastMessage,
    required this.time,
    required this.sender,
    this.status = MessageStatus.active,
    this.unreadCount = 0,
  });
}

class ChatMessage {
  final String id;
  final String content;
  final String time;
  final MessageSender sender;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.content,
    required this.time,
    required this.sender,
    this.isRead = false,
  });
}
