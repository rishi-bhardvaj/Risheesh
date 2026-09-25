import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/features/ai/data/ollama_provider.dart';
import 'package:career_os/features/ai/domain/ai_action_parser.dart';
import 'package:career_os/features/ai/domain/ai_action_service.dart';
import 'package:career_os/features/ai/domain/ai_context_builder.dart';
import 'package:career_os/features/ai/domain/ai_models.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 6: Ollama Provider & Connection Tests', () {
    test('OllamaProvider tests connection successfully with model discovery', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/tags') {
          return http.Response(
            jsonEncode({
              'models': [
                {'name': 'llama3:latest', 'size': 4000000000},
                {'name': 'mistral:latest', 'size': 4500000000},
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final provider = OllamaProvider(client: mockClient);
      const config = OllamaConfig(
        host: '127.0.0.1',
        port: 11434,
        selectedModel: 'llama3:latest',
      );

      final result = await provider.testConnection(config);
      expect(result.isSuccess, isTrue);
      expect(result.models.length, equals(2));
      expect(result.models, contains('llama3:latest'));
      expect(result.isConfiguredModelAvailable, isTrue);
    });

    test('OllamaProvider flags model unavailable when installed models list does not match', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'models': [
              {'name': 'mistral:latest'},
            ]
          }),
          200,
        );
      });

      final provider = OllamaProvider(client: mockClient);
      const config = OllamaConfig(
        host: '127.0.0.1',
        port: 11434,
        selectedModel: 'deepseek-r1:latest',
      );

      final result = await provider.testConnection(config);
      expect(result.isSuccess, isTrue);
      expect(result.isConfiguredModelAvailable, isFalse);
    });

    test('OllamaProvider streamChatResponse parses NDJSON stream correctly', () async {
      final mockClient = MockClient.streaming((request, requestStream) async {
        final stream = Stream<List<int>>.fromIterable([
          utf8.encode('{"message": {"role": "assistant", "content": "Hello "}, "done": false}\n'),
          utf8.encode('{"message": {"role": "assistant", "content": "World!"}, "done": true}\n'),
        ]);
        return http.StreamedResponse(stream, 200);
      });

      final provider = OllamaProvider(client: mockClient);
      const config = OllamaConfig();

      final chunks = <String>[];
      await for (final token in provider.streamChatResponse(
        config: config,
        systemPrompt: 'System',
        messages: [const AIMessageInput(role: 'user', content: 'Hi')],
      )) {
        chunks.add(token);
      }

      expect(chunks.join(''), equals('Hello World!'));
    });
  });

  group('Phase 6: Context Builder & Anti-Injection Tests', () {
    test('AIContextBuilder detects multiple query intents accurately', () {
      final builder = AIContextBuilder(db);
      
      expect(builder.detectIntents('What should I focus on today?'), contains(ContextFocus.dailyPlanning));
      expect(builder.detectIntents('Review my job applications for Google and interview'), contains(ContextFocus.career));
      expect(builder.detectIntents('What work tasks and blockers do I have for standup?'), contains(ContextFocus.work));
      expect(builder.detectIntents('Which DSA problems should I revise on LeetCode?'), contains(ContextFocus.dsa));
      expect(builder.detectIntents('What are my freelance proposals and client revenue?'), contains(ContextFocus.freelance));
      expect(builder.detectIntents('What is my total expense and budget this month?'), contains(ContextFocus.finance));
      expect(builder.detectIntents('How is my workout log and body weight?'), contains(ContextFocus.fitness));
    });

    test('AIContextBuilder marks data as untrusted and tags database records', () async {
      // Seed some tasks and career profile
      await db.upsertProfile(const UserProfilesCompanion(
        id: Value('user-1'),
        name: Value('Rishi'),
        preferredRoles: Value('Senior Flutter Architect'),
        skills: Value('Flutter, Dart, Riverpod, SQLite'),
      ));

      await db.insertTask(TasksCompanion(
        id: const Value('task-1'),
        title: const Value('Build Phase 6 AI Assistant'),
        category: const Value('work'),
        priority: const Value('high'),
        status: const Value('in_progress'),
        dueDate: Value(DateTime.now()),
      ));

      final builder = AIContextBuilder(db);
      final result = await builder.buildContext(
        query: 'What should I work on today?',
        maxContextLength: 4000,
      );

      expect(result.systemContext, contains('<database_context'));
      expect(result.systemContext, contains('is_untrusted_data="true"'));
      expect(result.systemContext, contains('Build Phase 6 AI Assistant'));
      expect(result.systemContext, contains('Senior Flutter Architect'));
      expect(result.tokenEstimate, greaterThan(0));
    });

    test('AIContextBuilder respects maximum context bounds', () async {
      // Insert multiple tasks
      for (int i = 0; i < 20; i++) {
        await db.insertTask(TasksCompanion(
          id: Value('task-$i'),
          title: Value('Task number $i with a detailed description of activities'),
          category: const Value('work'),
          priority: const Value('medium'),
          status: const Value('todo'),
        ));
      }

      final builder = AIContextBuilder(db);
      final result = await builder.buildContext(
        query: 'list all work tasks',
        maxContextLength: 500,
      );

      expect(result.systemContext.length, lessThanOrEqualTo(500));
    });
  });

  group('Phase 6: Action Parser Tests', () {
    test('AIActionParser extracts structured action and cleans conversational output', () {
      const responseText = '''
Here is your plan for today! I also suggest creating a reminder task:

```json:action
{
  "action": "CREATE_TASK",
  "payload": {
    "title": "Practice Dynamic Programming on LeetCode",
    "category": "personal",
    "priority": "high",
    "notes": "Solve 2 medium problems"
  }
}
```

Let me know if you would like me to adjust the priority!
''';

      final result = AIActionParser.parse(responseText);
      expect(result.cleanContent, contains('Here is your plan for today!'));
      expect(result.cleanContent, contains('Let me know if you would like me to adjust'));
      expect(result.cleanContent, isNot(contains('```json:action')));
      
      expect(result.actions.length, equals(1));
      final action = result.actions.first;
      expect(action.actionType, equals('CREATE_TASK'));
      expect(action.payload['title'], equals('Practice Dynamic Programming on LeetCode'));
      expect(action.payload['priority'], equals('high'));
      expect(action.isValid, isTrue);
    });

    test('AIActionParser rejects actions with missing required fields', () {
      const invalidActionText = '''
```json:action
{
  "action": "CREATE_TASK",
  "payload": {
    "notes": "No title provided!"
  }
}
```
''';

      final result = AIActionParser.parse(invalidActionText);
      expect(result.actions.length, equals(1));
      expect(result.actions.first.isValid, isFalse);
      expect(result.actions.first.validationError, contains('Missing title'));
    });

    test('AIActionParser parses multiple distinct actions (e.g. DSA Revision + Expense)', () {
      const multiActionText = '''
```json:action
{
  "action": "SET_DSA_REVISION_DATE",
  "payload": {
    "id": "dsa-101",
    "daysFromNow": 3
  }
}
```

And recorded your lunch:
```json:action
{
  "action": "CREATE_EXPENSE",
  "payload": {
    "amount": 150.0,
    "description": "Lunch meeting",
    "category": "Food & Dining"
  }
}
```
''';

      final result = AIActionParser.parse(multiActionText);
      expect(result.actions.length, equals(2));
      expect(result.actions[0].actionType, equals('SET_DSA_REVISION_DATE'));
      expect(result.actions[1].actionType, equals('CREATE_EXPENSE'));
    });
  });

  group('Phase 6: Action Execution & DB Mutation Tests', () {
    test('AIActionService executes CREATE_TASK and persists to tasks table', () async {
      final service = AIActionService(db);
      const proposal = StructuredActionProposal(
        actionType: 'CREATE_TASK',
        payload: {
          'title': 'Prepare for mock interview',
          'priority': 'high',
          'category': 'work',
        },
      );

      final result = await service.executeAction(proposal);
      expect(result.success, isTrue);

      final tasks = await db.getAllTasks();
      expect(tasks.any((t) => t.title == 'Prepare for mock interview' && t.category == 'work'), isTrue);
    });

    test('AIActionService executes SET_DSA_REVISION_DATE and updates revisionDate', () async {
      await db.insertDSAProblem(const DSAProblemsCompanion(
        id: Value('dsa-1'),
        title: Value('LRU Cache'),
        platform: Value('LeetCode'),
        topic: Value('Design'),
        difficulty: Value('Medium'),
      ));

      final service = AIActionService(db);
      const proposal = StructuredActionProposal(
        actionType: 'SET_DSA_REVISION_DATE',
        payload: {
          'id': 'dsa-1',
          'daysFromNow': 7,
        },
      );

      final result = await service.executeAction(proposal);
      expect(result.success, isTrue);

      final problem = await db.getDSAProblemById('dsa-1');
      expect(problem?.revisionDate != null, isTrue);
    });

    test('AIActionService executes CREATE_EXPENSE and CREATE_INCOME in Finance tables', () async {
      final service = AIActionService(db);

      const expenseProposal = StructuredActionProposal(
        actionType: 'CREATE_EXPENSE',
        payload: {
          'amount': 45.5,
          'category': 'Books & Courses',
          'description': 'System Design Handbook',
        },
      );

      const incomeProposal = StructuredActionProposal(
        actionType: 'CREATE_INCOME',
        payload: {
          'amount': 2500.0,
          'category': 'Freelance',
          'source': 'Mobile App Milestone 1',
        },
      );

      final expRes = await service.executeAction(expenseProposal);
      final incRes = await service.executeAction(incomeProposal);

      expect(expRes.success, isTrue);
      expect(incRes.success, isTrue);

      final expenses = await db.getAllExpenses();
      final incomes = await db.getAllIncomes();

      expect(expenses.length, equals(1));
      expect(expenses.first.description, equals('System Design Handbook'));
      expect(incomes.length, equals(1));
      expect(incomes.first.source, equals('Mobile App Milestone 1'));
    });
  });

  group('Phase 6: AI Conversations & Messages SQLite Persistence Tests', () {
    test('AI Conversations, Messages, and Actions lifecycle & cascade deletion', () async {
      const convId = 'conv-101';
      final now = DateTime.now();

      await db.insertAIConversation(AIConversationsCompanion(
        id: const Value(convId),
        title: const Value('Daily Planning Chat'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      await db.insertAIMessage(AIMessagesCompanion(
        id: const Value('msg-1'),
        conversationId: const Value(convId),
        role: const Value('user'),
        content: const Value('What is on my schedule?'),
        createdAt: Value(now),
      ));

      await db.insertAIMessage(AIMessagesCompanion(
        id: const Value('msg-2'),
        conversationId: const Value(convId),
        role: const Value('assistant'),
        content: const Value('Here is your plan for today.'),
        createdAt: Value(now),
      ));

      await db.insertAIAction(AIActionsCompanion(
        id: const Value('act-1'),
        conversationId: const Value(convId),
        messageId: const Value('msg-2'),
        actionType: const Value('CREATE_TASK'),
        payload: const Value('{"title": "Review PR"}'),
        status: const Value('PROPOSED'),
        createdAt: Value(now),
      ));

      final convs = await db.getAllAIConversations();
      final msgs = await db.getAIMessagesForConversation(convId);
      final acts = await db.getAIActionsForConversation(convId);

      expect(convs.length, equals(1));
      expect(msgs.length, equals(2));
      expect(acts.length, equals(1));
      expect(acts.first.actionType, equals('CREATE_TASK'));

      // Update action status
      await db.updateAIActionStatus('act-1', 'CONFIRMED', executedAt: DateTime.now());
      final updatedAct = await db.getAIActionById('act-1');
      expect(updatedAct?.status, equals('CONFIRMED'));
      expect(updatedAct?.executedAt != null, isTrue);

      // Deleting conversation cascades to messages and actions
      await db.deleteAIConversation(convId);
      expect((await db.getAllAIConversations()).isEmpty, isTrue);
      expect((await db.getAIMessagesForConversation(convId)).isEmpty, isTrue);
      expect((await db.getAIActionsForConversation(convId)).isEmpty, isTrue);
    });
  });
}
