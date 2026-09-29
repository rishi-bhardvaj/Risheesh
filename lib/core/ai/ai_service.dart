import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_provider.dart';
import 'ai_clients.dart';
import 'ai_keys.dart';

/// Routes each kind of task to the right model:
/// research -> Claude, documents -> Gemini, quick bulk text -> Nemotron
/// (or Claude at low effort when no NVIDIA key is set).
class AiService {
  final AiKeys keys;
  final SharedPreferences? prefs;
  final http.Client? client;

  AiService(this.keys, {this.prefs, this.client});

  static const _geminiModelKey = 'ai_gemini_model';
  static const _nemotronModelKey = 'ai_nemotron_model';

  ClaudeClient get claude {
    final key = keys[AiProvider.claude];
    if (key == null) throw const AiMissingKeyException(AiProvider.claude);
    return ClaudeClient(key, client: client);
  }

  GeminiClient get gemini {
    final key = keys[AiProvider.gemini];
    if (key == null) throw const AiMissingKeyException(AiProvider.gemini);
    return GeminiClient(key, model: prefs?.getString(_geminiModelKey), client: client);
  }

  NemotronClient? get nemotron {
    final key = keys[AiProvider.nemotron];
    return key == null ? null : NemotronClient(key, model: prefs?.getString(_nemotronModelKey), client: client);
  }

  /// Short text task (a few hundred words at most).
  Future<String> quick(String prompt, {String? system, int maxTokens = 1500}) async {
    final n = nemotron;
    if (n != null) {
      try {
        return await n.chat(prompt, system: system, maxTokens: maxTokens);
      } on AiException catch (e) {
        if (e.isAuth || keys[AiProvider.claude] == null) rethrow;
        // Otherwise fall through to Claude.
      }
    }
    return claude.complete(prompt, system: system, effort: 'low', maxTokens: maxTokens);
  }

  /// Long-form document / research writing.
  Future<String> longForm(String prompt, {String? system}) => gemini.generate(prompt, system: system);

  /// Checks a key against its provider and remembers the model it can use.
  /// Returns the model id (or "ok").
  Future<String> verify(AiProvider provider, String key) async {
    switch (provider) {
      case AiProvider.claude:
        await ClaudeClient(key, client: client).validate();
        return ClaudeClient.model;
      case AiProvider.gemini:
        final model = await GeminiClient.pickModel(key, client: client);
        await prefs?.setString(_geminiModelKey, model);
        return model;
      case AiProvider.nemotron:
        final model = await NemotronClient.pickModel(key, client: client);
        await NemotronClient(key, model: model, client: client).validate();
        await prefs?.setString(_nemotronModelKey, model);
        return model;
    }
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {
    prefs = null; // tests without prefs override
  }
  return AiService(ref.watch(aiKeysProvider), prefs: prefs);
});
