// AI Provider Interface Definition for future Local Ollama & Remote APIs

abstract class AIProvider {
  String get providerName;
  bool get isConfigured;

  Future<bool> testConnection();

  Future<String> generateResponse({
    required String prompt,
    Map<String, dynamic>? structuredContext,
  });

  Future<String> generateEODUpdate({
    required List<String> completedTasks,
    required List<String> inProgressTasks,
    String? blockers,
    String? tomorrowPlan,
  });

  Future<String> analyzeJobMatch({
    required String jobDescription,
    required String userProfileSummary,
  });
}

class OllamaConfig {
  final String host;
  final int port;
  final String model;
  final bool enableThinking;
  final int timeoutSeconds;

  const OllamaConfig({
    this.host = 'http://127.0.0.1',
    this.port = 11434,
    this.model = 'llama3',
    this.enableThinking = true,
    this.timeoutSeconds = 60,
  });

  String get endpointUrl => '$host:$port';
}

