import 'ai_models.dart';

/// Abstract contract for AI providers (e.g. Ollama, Open-AI compatible, etc.)
abstract class AIProvider {
  /// Test connection to the AI backend and return status and available models
  Future<ConnectionTestResult> testConnection(OllamaConfig config);

  /// Fetch list of available installed models
  Future<List<String>> getAvailableModels(OllamaConfig config);

  /// Stream chat tokens from the model
  Stream<String> streamChatResponse({
    required OllamaConfig config,
    required String systemPrompt,
    required List<AIMessageInput> messages,
  });

  /// Single non-streaming chat generation
  Future<String> generateChatResponse({
    required OllamaConfig config,
    required String systemPrompt,
    required List<AIMessageInput> messages,
  });
}
