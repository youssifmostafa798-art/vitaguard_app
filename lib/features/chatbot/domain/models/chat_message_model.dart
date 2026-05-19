enum MessageIntent {
  normal,
  emergency,
  warning,
  tip,
  question,
}

sealed class ChatBlock {}

class ParagraphBlock extends ChatBlock {
  final String text;
  ParagraphBlock(this.text);
}

class BulletBlock extends ChatBlock {
  final List<String> items;
  BulletBlock(this.items);
}

class SpacerBlock extends ChatBlock {}

class ChatMessageModel {
  final String text;
  final MessageIntent intent;
  final List<ChatBlock> blocks;
  final bool isValid;

  const ChatMessageModel({
    required this.text,
    required this.intent,
    required this.blocks,
    required this.isValid,
  });
}
