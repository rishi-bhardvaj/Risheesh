import 'dart:convert';

/// Configuration for the Ollama connection
class OllamaConfig {
  final String host;
  final int port;
  final String selectedModel;
  final int timeoutSeconds;
  final int contextLength;
  final double temperature;
  final bool requireConfirmationForActions;

  const OllamaConfig({
    this.host = '127.0.0.1',
    this.port = 11434,
    this.selectedModel = 'llama3:latest',
    this.timeoutSeconds = 30,
    this.contextLength = 4096,
    this.temperature = 0.7,
    this.requireConfirmationForActions = true,
  });

  String get baseUrl {
    String cleanHost = host.trim();
    if (!cleanHost.startsWith('http://') && !cleanHost.startsWith('https://')) {
      cleanHost = 'http://$cleanHost';
    }
    // Remove trailing slash if present
    if (cleanHost.endsWith('/')) {
      cleanHost = cleanHost.substring(0, cleanHost.length - 1);
    }
    // If host already has port specified, don't duplicate
    final uri = Uri.parse(cleanHost);
    if (uri.hasPort) {
      return cleanHost;
    }
    return '$cleanHost:$port';
  }

  OllamaConfig copyWith({
    String? host,
    int? port,
    String? selectedModel,
    int? timeoutSeconds,
    int? contextLength,
    double? temperature,
    bool? requireConfirmationForActions,
  }) {
    return OllamaConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      selectedModel: selectedModel ?? this.selectedModel,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      contextLength: contextLength ?? this.contextLength,
      temperature: temperature ?? this.temperature,
      requireConfirmationForActions: requireConfirmationForActions ?? this.requireConfirmationForActions,
    );
  }

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'selectedModel': selectedModel,
        'timeoutSeconds': timeoutSeconds,
        'contextLength': contextLength,
        'temperature': temperature,
        'requireConfirmationForActions': requireConfirmationForActions,
      };

  factory OllamaConfig.fromJson(Map<String, dynamic> json) => OllamaConfig(
        host: json['host'] as String? ?? '127.0.0.1',
        port: json['port'] as int? ?? 11434,
        selectedModel: json['selectedModel'] as String? ?? 'llama3:latest',
        timeoutSeconds: json['timeoutSeconds'] as int? ?? 30,
        contextLength: json['contextLength'] as int? ?? 4096,
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
        requireConfirmationForActions: json['requireConfirmationForActions'] as bool? ?? true,
      );
}

/// Result of testing connection to AI server
class ConnectionTestResult {
  final bool isSuccess;
  final String message;
  final List<String> models;
  final int latencyMs;
  final bool isConfiguredModelAvailable;

  const ConnectionTestResult({
    required this.isSuccess,
    required this.message,
    this.models = const [],
    this.latencyMs = 0,
    this.isConfiguredModelAvailable = false,
  });

  factory ConnectionTestResult.failure(String message) => ConnectionTestResult(
        isSuccess: false,
        message: message,
      );
}

/// Message role and input
class AIMessageInput {
  final String role; // 'system', 'user', 'assistant'
  final String content;

  const AIMessageInput({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

/// Result of context building
class ContextBuildResult {
  final String systemContext;
  final Map<String, int> recordCounts;
  final int tokenEstimate;

  const ContextBuildResult({
    required this.systemContext,
    required this.recordCounts,
    required this.tokenEstimate,
  });
}

/// Action types recognized by Career OS
enum AIActionType {
  createTask,
  updateTaskStatus,
  saveJob,
  updateApplicationStatus,
  setDsaRevisionDate,
  createExpense,
  createIncome,
  unknown,
}

/// Status of action proposal
enum AIActionStatus {
  proposed,
  confirmed,
  cancelled,
  executed,
  failed,
}

/// Action proposal extracted from AI response
class StructuredActionProposal {
  final String? id;
  final String actionType;
  final Map<String, dynamic> payload;
  final bool isValid;
  final String? validationError;

  const StructuredActionProposal({
    this.id,
    required this.actionType,
    required this.payload,
    this.isValid = true,
    this.validationError,
  });

  String get jsonPayload => jsonEncode(payload);
}

/// Result of action execution
class ActionExecutionResult {
  final bool success;
  final String message;
  final dynamic createdEntity;

  const ActionExecutionResult({
    required this.success,
    required this.message,
    this.createdEntity,
  });
}
