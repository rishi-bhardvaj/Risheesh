import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../domain/ai_models.dart';
import '../domain/ai_provider.dart';

class OllamaProvider implements AIProvider {
  final http.Client _client;

  OllamaProvider({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<ConnectionTestResult> testConnection(OllamaConfig config) async {
    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse('${config.baseUrl}/api/tags');
      final response = await _client
          .get(uri)
          .timeout(Duration(seconds: config.timeoutSeconds));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final modelsList = (data['models'] as List<dynamic>?) ?? [];
        final modelNames = modelsList
            .map((m) => (m as Map<String, dynamic>)['name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

        final isAvailable = modelNames.any((m) =>
            m.toLowerCase() == config.selectedModel.toLowerCase() ||
            m.split(':').first.toLowerCase() == config.selectedModel.toLowerCase());

        return ConnectionTestResult(
          isSuccess: true,
          message: 'Connected to Ollama (${stopwatch.elapsedMilliseconds}ms). ${modelNames.length} models found.',
          models: modelNames,
          latencyMs: stopwatch.elapsedMilliseconds,
          isConfiguredModelAvailable: isAvailable,
        );
      } else {
        return ConnectionTestResult.failure(
          'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown response'}',
        );
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      return ConnectionTestResult.failure(
        'Cannot reach Ollama at ${config.baseUrl}. Make sure Ollama is running (`ollama serve`) and accessible. (${e.message})',
      );
    } on TimeoutException {
      stopwatch.stop();
      return ConnectionTestResult.failure(
        'Connection timed out after ${config.timeoutSeconds}s at ${config.baseUrl}. Check host/IP and network firewall.',
      );
    } catch (e) {
      stopwatch.stop();
      return ConnectionTestResult.failure('Connection error: $e');
    }
  }

  @override
  Future<List<String>> getAvailableModels(OllamaConfig config) async {
    try {
      final uri = Uri.parse('${config.baseUrl}/api/tags');
      final response = await _client
          .get(uri)
          .timeout(Duration(seconds: config.timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final modelsList = (data['models'] as List<dynamic>?) ?? [];
        return modelsList
            .map((m) => (m as Map<String, dynamic>)['name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<String> streamChatResponse({
    required OllamaConfig config,
    required String systemPrompt,
    required List<AIMessageInput> messages,
  }) async* {
    final uri = Uri.parse('${config.baseUrl}/api/chat');

    final payload = {
      'model': config.selectedModel,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        ...messages.map((m) => m.toJson()),
      ],
      'stream': true,
      'options': {
        'temperature': config.temperature,
        'num_ctx': config.contextLength,
      },
    };

    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(payload);

    final streamedResponse = await _client.send(request);

    if (streamedResponse.statusCode != 200) {
      final body = await streamedResponse.stream.bytesToString();
      throw Exception('Ollama error (${streamedResponse.statusCode}): $body');
    }

    String buffer = '';
    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      buffer += chunk;
      final lines = buffer.split('\n');
      // Keep the last incomplete fragment in buffer
      buffer = lines.removeLast();

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        try {
          final data = jsonDecode(trimmed) as Map<String, dynamic>;
          if (data.containsKey('message')) {
            final content = (data['message'] as Map<String, dynamic>)['content'] as String? ?? '';
            if (content.isNotEmpty) {
              yield content;
            }
          }
        } catch (_) {
          // If JSON parse fails on single line, ignore and proceed
        }
      }
    }

    if (buffer.trim().isNotEmpty) {
      try {
        final data = jsonDecode(buffer.trim()) as Map<String, dynamic>;
        if (data.containsKey('message')) {
          final content = (data['message'] as Map<String, dynamic>)['content'] as String? ?? '';
          if (content.isNotEmpty) {
            yield content;
          }
        }
      } catch (_) {}
    }
  }

  @override
  Future<String> generateChatResponse({
    required OllamaConfig config,
    required String systemPrompt,
    required List<AIMessageInput> messages,
  }) async {
    final buffer = StringBuffer();
    await for (final token in streamChatResponse(
      config: config,
      systemPrompt: systemPrompt,
      messages: messages,
    )) {
      buffer.write(token);
    }
    return buffer.toString();
  }
}
