import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_keys.dart';

class AiException implements Exception {
  final AiProvider provider;
  final String message;
  final int? statusCode;

  const AiException(this.provider, this.message, {this.statusCode});

  bool get isAuth => statusCode == 401 || statusCode == 403;

  @override
  String toString() => '${provider.label}: $message';
}

class AiMissingKeyException extends AiException {
  const AiMissingKeyException(AiProvider provider) : super(provider, 'No API key set. Add it in Settings → AI keys.');
}

/// Extracts the first JSON object/array from model text (handles ```json
/// fences and leading prose).
dynamic parseJsonLenient(String text) {
  final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
  final candidate = (fenced?.group(1) ?? text).trim();
  try {
    return jsonDecode(candidate);
  } catch (_) {
    final start = candidate.indexOf(RegExp(r'[\[{]'));
    if (start < 0) rethrow;
    final open = candidate[start];
    final close = open == '{' ? '}' : ']';
    final end = candidate.lastIndexOf(close);
    return jsonDecode(candidate.substring(start, end + 1));
  }
}

String _errorMessage(http.Response r) {
  try {
    final body = jsonDecode(utf8.decode(r.bodyBytes));
    final err = body is Map ? (body['error'] ?? body) : body;
    if (err is Map && err['message'] != null) return err['message'].toString();
    if (err is Map && err['detail'] != null) return err['detail'].toString();
    return err.toString();
  } catch (_) {
    return 'HTTP ${r.statusCode}';
  }
}

class WebSource {
  final String url;
  final String title;
  const WebSource(this.url, this.title);
}

class ClaudeResearchResult {
  final Map<String, dynamic> data;
  final List<WebSource> sources;
  final int webSearches;
  const ClaudeResearchResult(this.data, this.sources, this.webSearches);
}

/// Claude Messages API over raw HTTP (there is no official Dart SDK).
class ClaudeClient {
  static const model = 'claude-opus-5';
  static const _base = 'https://api.anthropic.com/v1';

  final String apiKey;
  final http.Client _http;

  ClaudeClient(this.apiKey, {http.Client? client}) : _http = client ?? http.Client();

  Map<String, String> get _headers => {
        'content-type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        // Re-runs a policy-declined request on Anthropic's recommended
        // fallback model instead of returning the refusal.
        'anthropic-beta': 'server-side-fallback-2026-07-01',
      };

  Future<bool> validate() async {
    final r = await _http
        .get(Uri.parse('$_base/models?limit=1'), headers: {'x-api-key': apiKey, 'anthropic-version': '2023-06-01'})
        .timeout(const Duration(seconds: 15));
    if (r.statusCode == 200) return true;
    throw AiException(AiProvider.claude, _errorMessage(r), statusCode: r.statusCode);
  }

  Future<Map<String, dynamic>> _create(Map<String, dynamic> body, {Duration timeout = const Duration(minutes: 5)}) async {
    final http.Response r;
    try {
      r = await _http
          .post(Uri.parse('$_base/messages'), headers: _headers, body: jsonEncode(body))
          .timeout(timeout);
    } on Exception catch (e) {
      throw AiException(AiProvider.claude, 'Network error: $e');
    }
    if (r.statusCode != 200) {
      throw AiException(AiProvider.claude, _errorMessage(r), statusCode: r.statusCode);
    }
    final msg = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (msg['stop_reason'] == 'refusal') {
      throw const AiException(AiProvider.claude, 'Claude declined this request.');
    }
    return msg;
  }

  /// Plain text completion.
  Future<String> complete(String prompt, {String? system, String effort = 'low', int maxTokens = 4000}) async {
    final msg = await _create({
      'model': model,
      'max_tokens': maxTokens,
      'fallbacks': 'default',
      'output_config': {'effort': effort},
      'system': ?system,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    });
    return (msg['content'] as List)
        .whereType<Map<String, dynamic>>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join('\n')
        .trim();
  }

  /// Web research with the server-side web search tool. Claude returns its
  /// findings by calling [resultTool] (strict schema), which makes the
  /// output reliably parseable alongside search citations.
  Future<ClaudeResearchResult> research({
    required String system,
    required String prompt,
    required String resultTool,
    required String resultDescription,
    required Map<String, dynamic> resultSchema,
    int maxSearches = 8,
    String effort = 'medium',
  }) async {
    final messages = <Map<String, dynamic>>[
      {'role': 'user', 'content': prompt},
    ];
    final sources = <String, WebSource>{};
    var searches = 0;
    var nudged = false;

    for (var turn = 0; turn < 6; turn++) {
      final msg = await _create({
        'model': model,
        'max_tokens': 16000,
        'fallbacks': 'default',
        'thinking': {'type': 'adaptive'},
        'output_config': {'effort': effort},
        'system': system,
        'tools': [
          {'type': 'web_search_20260209', 'name': 'web_search', 'max_uses': maxSearches},
          {
            'name': resultTool,
            'description': resultDescription,
            'strict': true,
            'input_schema': resultSchema,
          },
        ],
        'tool_choice': {'type': 'auto'},
        'messages': messages,
      });
      final content = (msg['content'] as List).whereType<Map<String, dynamic>>().toList();

      for (final block in content) {
        if (block['type'] == 'server_tool_use' && block['name'] == 'web_search') searches++;
        if (block['type'] == 'web_search_tool_result' && block['content'] is List) {
          for (final r in (block['content'] as List).whereType<Map<String, dynamic>>()) {
            final url = r['url']?.toString();
            if (url != null) sources[url] = WebSource(url, r['title']?.toString() ?? url);
          }
        }
      }

      final call = content.where((b) => b['type'] == 'tool_use' && b['name'] == resultTool).firstOrNull;
      if (call != null) {
        return ClaudeResearchResult(Map<String, dynamic>.from(call['input'] as Map), sources.values.toList(), searches);
      }

      final stop = msg['stop_reason'];
      if (stop == 'pause_turn') {
        // Server-side loop hit its iteration cap: resend as-is to resume.
        messages.add({'role': 'assistant', 'content': content});
        continue;
      }
      if (stop == 'max_tokens' || nudged) {
        throw const AiException(AiProvider.claude, 'Claude finished without returning results. Try a narrower search.');
      }
      messages
        ..add({'role': 'assistant', 'content': content})
        ..add({'role': 'user', 'content': 'Now call $resultTool with everything you found.'});
      nudged = true;
    }
    throw const AiException(AiProvider.claude, 'Search took too many steps. Try a narrower search.');
  }
}

/// Gemini REST (generativelanguage.googleapis.com). The model is picked from
/// what the key can access, preferring the newest stable "pro" model.
class GeminiClient {
  static const _base = 'https://generativelanguage.googleapis.com/v1beta';
  static const fallbackModel = 'gemini-2.5-pro';

  final String apiKey;
  final String model;
  final http.Client _http;

  GeminiClient(this.apiKey, {String? model, http.Client? client})
      : model = model ?? fallbackModel,
        _http = client ?? http.Client();

  static double _version(String name) =>
      double.tryParse(RegExp(r'gemini-(\d+(?:\.\d+)?)').firstMatch(name)?.group(1) ?? '') ?? 0;

  /// Lists models and returns the best text model id, e.g. "gemini-2.5-pro".
  static Future<String> pickModel(String apiKey, {http.Client? client}) async {
    final c = client ?? http.Client();
    final r = await c
        .get(Uri.parse('$_base/models?pageSize=200'), headers: {'x-goog-api-key': apiKey})
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw AiException(AiProvider.gemini, _errorMessage(r), statusCode: r.statusCode);
    final models = ((jsonDecode(utf8.decode(r.bodyBytes)) as Map)['models'] as List? ?? const [])
        .whereType<Map>()
        .where((m) => (m['supportedGenerationMethods'] as List? ?? const []).contains('generateContent'))
        .map((m) => (m['name'] as String).replaceFirst('models/', ''))
        .where((n) => n.startsWith('gemini-') && !RegExp(r'tts|image|embed|live|audio|vision|robotics|computer|lite').hasMatch(n))
        .toList();
    if (models.isEmpty) return fallbackModel;
    int rank(String n) {
      var s = (_version(n) * 100).round();
      if (n.contains('-pro')) s += 50;
      if (n.contains('preview') || n.contains('exp')) s -= 1000; // stable first
      return s;
    }

    models.sort((a, b) => rank(b).compareTo(rank(a)));
    return models.first;
  }

  Future<String> generate(String prompt, {String? system, bool json = false, int maxTokens = 16000}) async {
    final http.Response r;
    try {
      r = await _http
          .post(
            Uri.parse('$_base/models/$model:generateContent'),
            headers: {'content-type': 'application/json', 'x-goog-api-key': apiKey},
            body: jsonEncode({
              if (system != null)
                'systemInstruction': {
                  'parts': [
                    {'text': system},
                  ],
                },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {
                'maxOutputTokens': maxTokens,
                if (json) 'responseMimeType': 'application/json',
              },
            }),
          )
          .timeout(const Duration(minutes: 4));
    } on Exception catch (e) {
      throw AiException(AiProvider.gemini, 'Network error: $e');
    }
    if (r.statusCode != 200) throw AiException(AiProvider.gemini, _errorMessage(r), statusCode: r.statusCode);
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final candidates = data['candidates'] as List? ?? const [];
    if (candidates.isEmpty) {
      final reason = (data['promptFeedback'] as Map?)?['blockReason'];
      throw AiException(AiProvider.gemini, 'No output${reason != null ? ' (blocked: $reason)' : ''}.');
    }
    final parts = ((candidates.first as Map)['content'] as Map?)?['parts'] as List? ?? const [];
    final text = parts
        .whereType<Map>()
        .where((p) => p['thought'] != true && p['text'] != null)
        .map((p) => p['text'] as String)
        .join();
    if (text.trim().isEmpty) throw const AiException(AiProvider.gemini, 'Empty response.');
    return text.trim();
  }
}

/// NVIDIA API catalog (OpenAI-compatible chat completions).
class NemotronClient {
  static const _base = 'https://integrate.api.nvidia.com/v1';
  static const defaultModel = 'nvidia/nemotron-3-super-120b-a12b';

  final String apiKey;
  final String model;
  final http.Client _http;

  NemotronClient(this.apiKey, {String? model, http.Client? client})
      : model = model ?? defaultModel,
        _http = client ?? http.Client();

  static Future<String> pickModel(String apiKey, {http.Client? client}) async {
    final c = client ?? http.Client();
    final r = await c
        .get(Uri.parse('$_base/models'), headers: {'authorization': 'Bearer $apiKey'})
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw AiException(AiProvider.nemotron, _errorMessage(r), statusCode: r.statusCode);
    final ids = ((jsonDecode(utf8.decode(r.bodyBytes)) as Map)['data'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => m['id'].toString())
        .toList();
    const preferred = [defaultModel, 'nvidia/nemotron-3.5-lightning-30b-a3b', 'nvidia/llama-3.3-nemotron-super-49b-v1.5', 'nvidia/llama-3.1-nemotron-70b-instruct'];
    return preferred.firstWhere(ids.contains, orElse: () => defaultModel);
  }

  /// A cheap authenticated call; the model list is public, so validation
  /// has to hit chat completions.
  Future<bool> validate() async {
    await chat('Reply with OK.', maxTokens: 8);
    return true;
  }

  Future<String> chat(String prompt, {String? system, int maxTokens = 2048}) async {
    final http.Response r;
    try {
      r = await _http
          .post(
            Uri.parse('$_base/chat/completions'),
            headers: {'content-type': 'application/json', 'authorization': 'Bearer $apiKey'},
            body: jsonEncode({
              'model': model,
              'temperature': 0.3,
              'max_tokens': maxTokens,
              'messages': [
                if (system != null) {'role': 'system', 'content': system},
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 90));
    } on Exception catch (e) {
      throw AiException(AiProvider.nemotron, 'Network error: $e');
    }
    if (r.statusCode != 200) throw AiException(AiProvider.nemotron, _errorMessage(r), statusCode: r.statusCode);
    final data = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
    final text = ((data['choices'] as List).first as Map)['message']['content']?.toString() ?? '';
    // Reasoning variants prefix their answer with a <think> block.
    return text.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '').trim();
  }
}
