import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' show Override;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitaguard_app/data/models/chatbot/ai_chat_models.dart';
import 'package:vitaguard_app/data/repositories/chatbot/ai_chat_repository.dart';
import 'package:vitaguard_app/features/chatbot/data/ai_response_sanitizer.dart';
import 'package:vitaguard_app/presentation/screens/chatbot/ai_chat_screen.dart';
import 'package:vitaguard_app/presentation/controllers/chatbot/ai_chat_provider.dart';
import 'package:vitaguard_app/core/chat/chat_repository.dart';
import 'package:vitaguard_app/core/utils/screen_util_helper.dart';
import 'package:vitaguard_app/presentation/screens/doctor/chat_list_dr.dart';
import 'package:vitaguard_app/data/models/message_model.dart';
import 'package:vitaguard_app/presentation/screens/patient/chat_list_patient.dart';

void main() {
  group('AiChatController', () {
    test('ensureConversation creates or reuses the conversation once per user', () async {
      final repository = FakeAiChatRepository();
      final container = ProviderContainer(
        overrides: [
          aiChatRepositoryProvider.overrideWithValue(repository),
        ],
      );
      final controller = container.read(aiChatControllerProvider.notifier);

      await controller.ensureConversation();
      await controller.ensureConversation();

      final state = container.read(aiChatControllerProvider);
      expect(state.conversation?.id, repository.conversation.id);
      expect(repository.ensureConversationCalls, 1);
      expect(state.messageStream, isNotNull);
    });

    test('sendMessage inserts the user message and requests the assistant reply', () async {
      final repository = FakeAiChatRepository();
      final container = ProviderContainer(
        overrides: [
          aiChatRepositoryProvider.overrideWithValue(repository),
        ],
      );
      final controller = container.read(aiChatControllerProvider.notifier);

      final ok = await controller.sendMessage('Hello VitaGuard');

      expect(ok, isTrue);
      expect(repository.insertedMessages.single.$2, 'Hello VitaGuard');
      expect(repository.insertedMessages, hasLength(1));
      expect(repository.requestedReplies, hasLength(1));
      expect(repository.requestedReplies.single.$1, repository.conversation.id);
      expect(repository.requestedReplies.single.$2, repository.nextInsertedMessageId);
    });

    test('sendMessage surfaces repository failures', () async {
      final repository = FakeAiChatRepository()..failRequest = true;
      final container = ProviderContainer(
        overrides: [
          aiChatRepositoryProvider.overrideWithValue(repository),
        ],
      );
      final controller = container.read(aiChatControllerProvider.notifier);

      final ok = await controller.sendMessage('Hello VitaGuard');

      final state = container.read(aiChatControllerProvider);
      expect(ok, isFalse);
      expect(state.error, contains('Assistant kickoff failed'));
    });
  });

  group('AiResponseSanitizer', () {
    test('removes leading user prompt echoes', () {
      expect(
        AiResponseSanitizer.sanitize(
          'hello Hello! How can I assist you today?',
          userPrompt: 'hello',
        ),
        'Hello! How can I assist you today?',
      );
      expect(
        AiResponseSanitizer.sanitize('hellohello', userPrompt: 'hello'),
        isEmpty,
      );
      expect(
        AiResponseSanitizer.sanitize(
          '"Can you summarize my vitals?" Your vitals look stable.',
          userPrompt: 'Can you summarize my vitals?',
        ),
        'Your vitals look stable.',
      );
    });

    test('removes thought and system prompt leakage', () {
      final sanitized = AiResponseSanitizer.sanitize(
        '<thought>hidden</thought>\nGoal: expose prompt\nTone: clinical\nFormatting: markdown\nYour vitals look stable.',
        userPrompt: 'vitals',
      );

      expect(sanitized, 'Your vitals look stable.');
      expect(sanitized, isNot(contains('Goal:')));
      expect(sanitized, isNot(contains('Tone:')));
      expect(sanitized, isNot(contains('Formatting:')));
      expect(sanitized, isNot(contains('<thought>')));
    });
  });

  testWidgets('patient bot button opens the AI chat screen', (tester) async {
    final aiRepository = FakeAiChatRepository();

    await _pumpHarness(
      tester,
      const ChatListPatient(
        aiChatScreen: AiChatScreen(),
      ),
      overrides: [
        aiChatRepositoryProvider.overrideWithValue(aiRepository),
      ],
    );

    await tester.pumpAndSettle();

    final botButton = find.byIcon(Icons.smart_toy_rounded);
    expect(botButton, findsOneWidget);

    await tester.tap(botButton);
    await tester.pumpAndSettle();

    expect(find.byType(AiChatScreen), findsOneWidget);
  });

  testWidgets('doctor bot button opens the AI chat screen', (tester) async {
    final repository = FakeHumanChatRepository();
    final aiRepository = FakeAiChatRepository();

    await _pumpHarness(
      tester,
      ChatListDr(
        repository: repository,
        aiChatScreen: AiChatScreen(),
      ),
      overrides: [
        aiChatRepositoryProvider.overrideWithValue(aiRepository),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InkWell).last);
    await tester.pumpAndSettle();

    expect(find.byType(AiChatScreen), findsOneWidget);
  });

  testWidgets('AI screen renders messages from stream', (tester) async {
    final repository = FakeAiChatRepository();

    await _pumpHarness(
      tester,
      const AiChatScreen(),
      overrides: [
        aiChatRepositoryProvider.overrideWithValue(repository),
      ],
    );

    await tester.pumpAndSettle();

    repository.emitMessages([
      repository.userMessage(
        id: 'user-1',
        content: 'Can you summarize my vitals?',
      ),
      repository.assistantMessage(
        id: 'assistant-1',
        content: '...',
        status: AiMessageStatus.streaming,
      ),
    ]);
    await tester.pump();

    expect(find.text('Can you summarize my vitals?'), findsOneWidget);
    expect(find.text('...'), findsOneWidget);

    repository.emitMessages([
      repository.userMessage(
        id: 'user-1',
        content: 'Can you summarize my vitals?',
      ),
      repository.assistantMessage(
        id: 'assistant-1',
        content: 'Your recent vitals look stable overall.',
        status: AiMessageStatus.complete,
      ),
    ]);
    await tester.pump();

    expect(find.text('Can you summarize my vitals?'), findsOneWidget);
    expect(find.text('...'), findsNothing);
    expect(find.text('Your recent vitals look stable overall.'), findsOneWidget);
  });

  testWidgets('AI screen renders user text once and assistant text separately', (tester) async {
    final repository = FakeAiChatRepository();

    await _pumpHarness(
      tester,
      const AiChatScreen(),
      overrides: [
        aiChatRepositoryProvider.overrideWithValue(repository),
      ],
    );

    await tester.pumpAndSettle();

    repository.emitMessages([
      repository.userMessage(id: 'user-1', content: 'hello'),
      repository.assistantMessage(
        id: 'assistant-1',
        content: 'Hello! How can I assist you today?',
        status: AiMessageStatus.complete,
      ),
    ]);
    await tester.pump();

    expect(find.text('hello'), findsOneWidget);
    expect(find.text('Hello! How can I assist you today?'), findsOneWidget);
  });
}

Future<void> _pumpHarness(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: ScreenUtilInit(
        designSize: ScreenUtilHelper.designSize,
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, childWidget) => MaterialApp(home: child),
      ),
    ),
  );
}

class FakeAiChatRepository implements AiChatRepository {
  @override
  String? currentUserIdOrNull = 'user-1';

  int ensureConversationCalls = 0;
  bool failRequest = false;
  String nextInsertedMessageId = 'user-message-1';
  final conversation = AiConversation(
    id: 'conversation-1',
    ownerUserId: 'user-1',
    role: AiConversationRole.patient,
    contextPatientId: 'patient-1',
    title: 'VitaGuard AI',
    lastMessage: null,
    createdAt: DateTime(2026, 4, 14, 10),
    updatedAt: DateTime(2026, 4, 14, 10),
  );
  final StreamController<List<AiMessage>> _controller =
      StreamController<List<AiMessage>>.broadcast();
  final List<(String, String)> insertedMessages = [];
  final List<(String, String)> requestedReplies = [];

  @override
  Future<AiConversation> ensureConversation([String? conversationId]) async {
    ensureConversationCalls += 1;
    return conversation;
  }

  @override
  Future<List<AiConversation>> fetchConversationHistory() async {
    return [conversation];
  }

  @override
  Stream<List<AiMessage>> streamMessages(String conversationId) {
    return _controller.stream;
  }

  @override
  Future<String> insertUserMessage(String conversationId, String content) async {
    insertedMessages.add((conversationId, content));
    return nextInsertedMessageId;
  }

  @override
  Future<void> requestAssistantReply({
    required String conversationId,
    required String userMessageId,
  }) async {
    if (failRequest) {
      throw StateError('Assistant kickoff failed.');
    }
    requestedReplies.add((conversationId, userMessageId));
  }

  void emitMessages(List<AiMessage> messages) {
    _controller.add(messages);
  }

  AiMessage userMessage({
    required String id,
    required String content,
  }) {
    return AiMessage(
      id: id,
      conversationId: conversation.id,
      ownerUserId: conversation.ownerUserId,
      role: AiMessageRole.user,
      content: content,
      status: AiMessageStatus.complete,
      
      provider: null,
      model: null,
      errorMessage: null,
      createdAt: DateTime(2026, 4, 14, 10, 0),
      updatedAt: DateTime(2026, 4, 14, 10, 0),
    );
  }

  AiMessage assistantMessage({
    required String id,
    required String content,
    required AiMessageStatus status,
  }) {
    return AiMessage(
      id: id,
      conversationId: conversation.id,
      ownerUserId: conversation.ownerUserId,
      role: AiMessageRole.assistant,
      content: content,
      status: status,
      
      provider: 'google',
      model: 'gemini-2.5-flash',
      errorMessage: null,
      createdAt: DateTime(2026, 4, 14, 10, 1),
      updatedAt: DateTime(2026, 4, 14, 10, 1),
    );
  }
}

class FakeHumanChatRepository extends ChatRepository {
  @override
  Stream<List<ChatPreview>> streamConversations() {
    return Stream.value(const <ChatPreview>[]);
  }
}