import 'dart:convert';
import 'ai_models.dart';

class ParseActionResult {
  final String cleanContent;
  final List<StructuredActionProposal> actions;

  const ParseActionResult({
    required this.cleanContent,
    required this.actions,
  });
}

class AIActionParser {
  static final RegExp _actionBlockRegex = RegExp(
    r'```(?:json:action|action|json)\s*([\s\S]*?)\s*```',
    multiLine: true,
  );

  static ParseActionResult parse(String text) {
    final actions = <StructuredActionProposal>[];
    String cleanText = text;

    final matches = _actionBlockRegex.allMatches(text);
    for (final match in matches) {
      final jsonString = match.group(1)?.trim();
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final data = jsonDecode(jsonString);
          if (data is Map<String, dynamic> && data.containsKey('action')) {
            final actionType = data['action'] as String? ?? 'unknown';
            final payload = (data['payload'] as Map<String, dynamic>?) ?? {};
            
            final validationError = _validateAction(actionType, payload);
            actions.add(StructuredActionProposal(
              actionType: actionType,
              payload: payload,
              isValid: validationError == null,
              validationError: validationError,
            ));
          }
        } catch (_) {
          // If JSON parse fails, not a valid structured action
        }
      }
    }

    if (actions.isNotEmpty) {
      cleanText = text.replaceAll(_actionBlockRegex, '').trim();
    }

    return ParseActionResult(
      cleanContent: cleanText,
      actions: actions,
    );
  }

  static String? _validateAction(String type, Map<String, dynamic> payload) {
    switch (type.toUpperCase()) {
      case 'CREATE_TASK':
        if (payload['title'] == null || (payload['title'] as String).trim().isEmpty) {
          return 'Missing title in task payload';
        }
        return null;
      case 'UPDATE_TASK_STATUS':
        if (payload['id'] == null) return 'Missing task id';
        if (payload['status'] == null) return 'Missing target status';
        return null;
      case 'SAVE_JOB':
        if (payload['title'] == null || payload['company'] == null) {
          return 'Missing title or company in job payload';
        }
        return null;
      case 'UPDATE_APPLICATION_STATUS':
        if (payload['id'] == null || payload['status'] == null) {
          return 'Missing application id or status';
        }
        return null;
      case 'SET_DSA_REVISION_DATE':
        if (payload['id'] == null) return 'Missing DSA problem id';
        return null;
      case 'CREATE_EXPENSE':
        if (payload['amount'] == null || payload['description'] == null) {
          return 'Missing amount or description for expense';
        }
        return null;
      case 'CREATE_INCOME':
        if (payload['amount'] == null || payload['source'] == null) {
          return 'Missing amount or source for income';
        }
        return null;
      default:
        return 'Unsupported action type "$type"';
    }
  }
}
