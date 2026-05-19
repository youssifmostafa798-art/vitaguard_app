import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitaguard_app/data/models/chatbot/ai_chat_models.dart';
import 'package:vitaguard_app/presentation/widgets/chatbot/ai_message_bubble.dart';

void main() {
  AiMessage assistantMessage({required List<String>? quickReplies}) {
    final now = DateTime.utc(2026, 5, 19, 12);
    return AiMessage(
      id: 'assistant-1',
      conversationId: 'conversation-1',
      ownerUserId: 'user-1',
      role: AiMessageRole.assistant,
      content: 'How can I help next?',
      status: AiMessageStatus.complete,
      provider: 'gemini',
      model: 'gemma',
      errorMessage: null,
      createdAt: now,
      updatedAt: now,
      quickReplies: quickReplies,
    );
  }

  Widget testHost({
    required bool isLastMessage,
    required bool allowQuickReplies,
  }) {
    return ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) {
          return MaterialApp(
            home: Scaffold(
              body: AiMessageBubble(
                message: assistantMessage(
                  quickReplies: const ['Follow up', 'Explain more'],
                ),
                isPreviousSameSender: false,
                isLastMessage: isLastMessage,
                allowQuickReplies: allowQuickReplies,
              ),
            ),
          );
        },
      ),
    );
  }

  testWidgets(
    'quick reply chips only appear on the latest non-historical completed message',
    (tester) async {
      await tester.pumpWidget(
        testHost(isLastMessage: true, allowQuickReplies: true),
      );
      expect(find.widgetWithText(ActionChip, 'Follow up'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Explain more'), findsOneWidget);

      await tester.pumpWidget(
        testHost(isLastMessage: false, allowQuickReplies: true),
      );
      expect(find.widgetWithText(ActionChip, 'Follow up'), findsNothing);
      expect(find.widgetWithText(ActionChip, 'Explain more'), findsNothing);

      await tester.pumpWidget(
        testHost(isLastMessage: true, allowQuickReplies: false),
      );
      expect(find.widgetWithText(ActionChip, 'Follow up'), findsNothing);
      expect(find.widgetWithText(ActionChip, 'Explain more'), findsNothing);
    },
  );
}
