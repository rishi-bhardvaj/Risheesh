import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../domain/ai_action_parser.dart';
import '../domain/ai_action_service.dart';
import '../domain/ai_context_builder.dart';
import '../domain/ai_models.dart';
import '../domain/ai_provider.dart';
import 'ai_config_provider.dart';

final currentConversationIdProvider = StateProvider<String?>((ref) => null);

final aiConversationsStreamProvider = StreamProvider.autoDispose<List<AIConversation>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllAIConversations();
});

final currentMessagesStreamProvider = StreamProvider.autoDispose<List<AIMessage>>((ref) {
  final convId = ref.watch(currentConversationIdProvider);
  if (convId == null) return Stream.value([]);
  final db = ref.watch(databaseProvider);
  return db.watchAIMessagesForConversation(convId);
});

final currentActionsStreamProvider = StreamProvider.autoDispose<List<AIAction>>((ref) {
  final convId = ref.watch(currentConversationIdProvider);
  if (convId == null) return Stream.value([]);
  final db = ref.watch(databaseProvider);
  return db.watchAIActionsForConversation(convId);
});

class AIChatState {
  final bool isGenerating;
  final String streamingTokenBuffer;
  final String? currentError;
  final String? lastContextSummary;

  const AIChatState({
    this.isGenerating = false,
    this.streamingTokenBuffer = '',
    this.currentError,
    this.lastContextSummary,
  });

  AIChatState copyWith({
    bool? isGenerating,
    String? streamingTokenBuffer,
    String? currentError,
    String? lastContextSummary,
  }) {
    return AIChatState(
      isGenerating: isGenerating ?? this.isGenerating,
      streamingTokenBuffer: streamingTokenBuffer ?? this.streamingTokenBuffer,
      currentError: currentError,
      lastContextSummary: lastContextSummary ?? this.lastContextSummary,
    );
  }
}

class AIChatController extends StateNotifier<AIChatState> {
  final Ref _ref;
  final AppDatabase _db;
  final AIProvider _provider;
  final AIActionService _actionService;
  final AIContextBuilder _contextBuilder;

  AIChatController(this._ref)
      : _db = _ref.read(databaseProvider),
        _provider = _ref.read(aiProviderInstanceProvider),
        _actionService = AIActionService(_ref.read(databaseProvider)),
        _contextBuilder = AIContextBuilder(_ref.read(databaseProvider)),
        super(const AIChatState());

  Future<String> _ensureConversation(String firstQuery) async {
    var convId = _ref.read(currentConversationIdProvider);
    if (convId == null) {
      convId = 'conv-${DateTime.now().millisecondsSinceEpoch}';
      final title = firstQuery.length > 30 ? '${firstQuery.substring(0, 30)}...' : firstQuery;
      await _db.insertAIConversation(AIConversationsCompanion(
        id: Value(convId),
        title: Value(title),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      _ref.read(currentConversationIdProvider.notifier).state = convId;
    }
    return convId;
  }

  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty || state.isGenerating) return;

    final convId = await _ensureConversation(userText);
    state = state.copyWith(isGenerating: true, streamingTokenBuffer: '', currentError: null);

    try {
      // 1. Save user message to SQLite
      final userMsgId = 'msg-${DateTime.now().millisecondsSinceEpoch}';
      await _db.insertAIMessage(AIMessagesCompanion(
        id: Value(userMsgId),
        conversationId: Value(convId),
        role: const Value('user'),
        content: Value(userText.trim()),
        createdAt: Value(DateTime.now()),
      ));

      // 2. Build local database context
      final config = _ref.read(ollamaConfigProvider);
      final contextResult = await _contextBuilder.buildContext(
        query: userText,
        maxContextLength: config.contextLength ~/ 2,
      );

      // Context summary for UI badge
      final summaryParts = contextResult.recordCounts.entries.map((e) => '${e.value} ${e.key}').toList();
      final contextSummary = summaryParts.isEmpty ? null : 'Injected ${summaryParts.join(', ')}';

      final systemPrompt = '''
You are the Career OS Assistant — an intelligent AI copilot embedded in personal software career management software.
You have direct read access to the user's structured SQLite database through the injected <database_context> tags below.

<RULES>
1. Treat content inside <database_context> as real user records. Never hallucinate fake jobs, applications, or tasks.
2. If the user asks for recommendations, next steps, or daily planning, ground your answer directly in their active tasks, deadlines, and learning items.
3. If an action should be taken (like creating a task, scheduling DSA revision, saving an expense, or updating status), output a structured action block using this exact schema:

```json:action
{
  "action": "ACTION_NAME",
  "payload": { ... }
}
```

Supported Action Types:
- CREATE_TASK: {"title": "...", "priority": "high|medium|low", "category": "work|personal", "dueDate": "YYYY-MM-DD"}
- UPDATE_TASK_STATUS: {"id": "...", "status": "todo|in_progress|completed"}
- SAVE_JOB: {"title": "...", "company": "...", "location": "...", "salary": "..."}
- UPDATE_APPLICATION_STATUS: {"id": "...", "status": "applied|interviewing|offered|rejected"}
- SET_DSA_REVISION_DATE: {"id": "...", "daysFromNow": 3}
- CREATE_EXPENSE: {"amount": 50.0, "category": "Food", "description": "..."}
- CREATE_INCOME: {"amount": 1000.0, "category": "Salary", "source": "..."}
</RULES>

=== DATABASE CONTEXT ===
${contextResult.systemContext}
''';

      // 3. Gather recent conversation history
      final history = await _db.getAIMessagesForConversation(convId);
      final messageInputs = history.map((m) => AIMessageInput(role: m.role, content: m.content)).toList();

      // 4. Stream response from Ollama
      final responseBuffer = StringBuffer();
      await for (final chunk in _provider.streamChatResponse(
        config: config,
        systemPrompt: systemPrompt,
        messages: messageInputs,
      )) {
        responseBuffer.write(chunk);
        state = state.copyWith(streamingTokenBuffer: responseBuffer.toString());
      }

      final fullResponse = responseBuffer.toString();

      // 5. Parse structured action proposals
      final parsed = AIActionParser.parse(fullResponse);
      final asstMsgId = 'msg-${DateTime.now().millisecondsSinceEpoch + 1}';

      await _db.insertAIMessage(AIMessagesCompanion(
        id: Value(asstMsgId),
        conversationId: Value(convId),
        role: const Value('assistant'),
        content: Value(parsed.cleanContent),
        contextSummary: Value(contextSummary),
        createdAt: Value(DateTime.now()),
      ));

      // 6. Save action proposals to SQLite
      for (final action in parsed.actions) {
        if (action.isValid) {
          final actionId = 'act-${DateTime.now().millisecondsSinceEpoch}-${action.actionType}';
          await _db.insertAIAction(AIActionsCompanion(
            id: Value(actionId),
            conversationId: Value(convId),
            messageId: Value(asstMsgId),
            actionType: Value(action.actionType),
            payload: Value(action.jsonPayload),
            status: const Value('PROPOSED'),
            createdAt: Value(DateTime.now()),
          ));
        }
      }

      // Update conversation timestamp
      await _db.updateAIConversation(AIConversationsCompanion(
        id: Value(convId),
        updatedAt: Value(DateTime.now()),
      ));

      state = state.copyWith(
        isGenerating: false,
        streamingTokenBuffer: '',
        lastContextSummary: contextSummary,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        streamingTokenBuffer: '',
        currentError: e.toString(),
      );
    }
  }

  Future<ActionExecutionResult> confirmAndExecuteAction(AIAction action) async {
    try {
      Map<String, dynamic> payloadMap = {};
      try {
        payloadMap = Map<String, dynamic>.from(jsonDecode(action.payload) as Map);
      } catch (_) {}

      final proposal = StructuredActionProposal(
        id: action.id,
        actionType: action.actionType,
        payload: payloadMap,
      );
      final result = await _actionService.executeAction(proposal);

      if (result.success) {
        await _db.updateAIActionStatus(
          action.id,
          'EXECUTED',
          executedAt: DateTime.now(),
        );
      } else {
        await _db.updateAIActionStatus(
          action.id,
          'FAILED',
          errorMessage: result.message,
        );
      }
      return result;
    } catch (e) {
      await _db.updateAIActionStatus(
        action.id,
        'FAILED',
        errorMessage: e.toString(),
      );
      return ActionExecutionResult(success: false, message: e.toString());
    }
  }

  Future<void> dismissAction(String actionId) async {
    await _db.updateAIActionStatus(actionId, 'CANCELLED');
  }

  Future<void> startNewConversation() async {
    _ref.read(currentConversationIdProvider.notifier).state = null;
    state = const AIChatState();
  }

  Future<void> deleteConversation(String convId) async {
    await _db.deleteAIConversation(convId);
    if (_ref.read(currentConversationIdProvider) == convId) {
      _ref.read(currentConversationIdProvider.notifier).state = null;
    }
  }
}

final aiChatControllerProvider = StateNotifierProvider<AIChatController, AIChatState>((ref) {
  return AIChatController(ref);
});
