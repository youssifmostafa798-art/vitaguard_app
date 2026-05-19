import 'models/chat_message_model.dart';

/// Normalizes raw text into structured ChatBlocks.
/// Completely removes the need for markdown parsing libraries.
class AiContentNormalizer {
  AiContentNormalizer._();

  static List<ChatBlock> normalize(String text) {
    if (text.trim().isEmpty) return [];

    final blocks = <ChatBlock>[];
    final lines = text.split('\n');

    List<String> currentParagraph = [];
    List<String> currentList = [];

    void flushParagraph() {
      if (currentParagraph.isNotEmpty) {
        // Strip out bold markers that span the whole paragraph if any
        String text = currentParagraph.join(' ').trim();
        // Optional: you can strip headers here if needed, e.g., ^#+\s+
        text = text.replaceAll(RegExp(r'^#+\s+'), '');
        blocks.add(ParagraphBlock(text));
        currentParagraph.clear();
      }
    }

    void flushList() {
      if (currentList.isNotEmpty) {
        blocks.add(BulletBlock(List.from(currentList)));
        currentList.clear();
      }
    }

    final bulletRegex = RegExp(r'^(\*|-|\d+\.|\.)\s+(.*)');

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        flushParagraph();
        flushList();
        continue;
      }

      final bulletMatch = bulletRegex.firstMatch(trimmed);
      if (bulletMatch != null) {
        flushParagraph();
        currentList.add(bulletMatch.group(2)!.trim());
      } else {
        flushList();
        currentParagraph.add(trimmed);
      }
    }

    flushParagraph();
    flushList();

    return blocks;
  }
}
