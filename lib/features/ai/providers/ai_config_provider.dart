import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/ollama_provider.dart';
import '../domain/ai_models.dart';
import '../domain/ai_provider.dart';

const String _kOllamaConfigKey = 'ollama_ai_config_v1';

class OllamaConfigNotifier extends StateNotifier<OllamaConfig> {
  OllamaConfigNotifier() : super(const OllamaConfig()) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kOllamaConfigKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        state = OllamaConfig.fromJson(data);
      }
    } catch (_) {}
  }

  Future<void> updateConfig(OllamaConfig newConfig) async {
    state = newConfig;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kOllamaConfigKey, jsonEncode(newConfig.toJson()));
    } catch (_) {}
  }
}

final ollamaConfigProvider = StateNotifierProvider<OllamaConfigNotifier, OllamaConfig>((ref) {
  return OllamaConfigNotifier();
});

final aiProviderInstanceProvider = Provider<AIProvider>((ref) {
  return OllamaProvider();
});

final connectionTestProvider = FutureProvider.autoDispose<ConnectionTestResult>((ref) async {
  final config = ref.watch(ollamaConfigProvider);
  final provider = ref.watch(aiProviderInstanceProvider);
  return provider.testConnection(config);
});

final availableModelsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final config = ref.watch(ollamaConfigProvider);
  final provider = ref.watch(aiProviderInstanceProvider);
  return provider.getAvailableModels(config);
});
