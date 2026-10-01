import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The three model providers and what each is used for.
///
/// * Claude: live web research (job search, business-lead discovery). Its
///   server-side web search tool returns cited, current results.
/// * Gemini: long-form generation (proposals, cover letters, research
///   reports rendered to PDF / DOCX). Long context, long outputs.
/// * Nemotron (optional): short bulk tasks (outreach drafts, job TL;DRs).
///   Falls back to Claude when no key is set.
enum AiProvider {
  claude('Claude', 'Live job search & business-lead discovery (web search)', 'https://console.anthropic.com/settings/keys', 'sk-ant-'),
  gemini('Gemini', 'PDFs, docs, proposals, cover letters & research reports', 'https://aistudio.google.com/apikey', 'AI'),
  nemotron('NVIDIA Nemotron', 'Optional: fast outreach drafts & job summaries', 'https://build.nvidia.com/settings/api-keys', 'nvapi-');

  final String label;
  final String purpose;
  final String keyUrl;
  final String keyPrefix;

  const AiProvider(this.label, this.purpose, this.keyUrl, this.keyPrefix);

  bool get required => false;
}

class AiKeys {
  final Map<AiProvider, String> _keys;

  const AiKeys([this._keys = const {}]);

  String? operator [](AiProvider p) {
    final k = _keys[p];
    return (k == null || k.trim().isEmpty) ? null : k.trim();
  }

  bool has(AiProvider p) => this[p] != null;
  bool get hasRequired => AiProvider.values.where((p) => p.required).every(has);

  AiKeys copyWith(AiProvider p, String? key) {
    final next = Map<AiProvider, String>.from(_keys);
    if (key == null || key.trim().isEmpty) {
      next.remove(p);
    } else {
      next[p] = key.trim();
    }
    return AiKeys(next);
  }
}

/// Persists keys in the platform keystore (Android Keystore-backed
/// EncryptedSharedPreferences), never in plain SharedPreferences or the DB.
abstract class AiKeyStore {
  Future<AiKeys> load();
  Future<void> save(AiProvider provider, String? key);
}

class SecureAiKeyStore implements AiKeyStore {
  static const _storage = FlutterSecureStorage();
  static String _name(AiProvider p) => 'ai_key_${p.name}';

  @override
  Future<AiKeys> load() async {
    var keys = const AiKeys();
    for (final p in AiProvider.values) {
      try {
        keys = keys.copyWith(p, await _storage.read(key: _name(p)));
      } catch (_) {
        // Keystore unavailable or entry corrupted: treat as not set.
      }
    }
    return keys;
  }

  @override
  Future<void> save(AiProvider provider, String? key) async {
    if (key == null || key.trim().isEmpty) {
      await _storage.delete(key: _name(provider));
    } else {
      await _storage.write(key: _name(provider), value: key.trim());
    }
  }
}

class MemoryAiKeyStore implements AiKeyStore {
  AiKeys keys;
  MemoryAiKeyStore([this.keys = const AiKeys()]);

  @override
  Future<AiKeys> load() async => keys;

  @override
  Future<void> save(AiProvider provider, String? key) async => keys = keys.copyWith(provider, key);
}

final aiKeyStoreProvider = Provider<AiKeyStore>((ref) => SecureAiKeyStore());

/// Loaded once in main() before runApp so the router can decide
/// synchronously whether to show the key setup screen.
final initialAiKeysProvider = Provider<AiKeys>((ref) => const AiKeys());

class AiKeysNotifier extends StateNotifier<AiKeys> {
  final AiKeyStore _store;

  AiKeysNotifier(this._store, AiKeys initial) : super(initial);

  Future<void> set(AiProvider provider, String? key) async {
    await _store.save(provider, key);
    state = state.copyWith(provider, key);
  }
}

final aiKeysProvider = StateNotifierProvider<AiKeysNotifier, AiKeys>(
  (ref) => AiKeysNotifier(ref.watch(aiKeyStoreProvider), ref.watch(initialAiKeysProvider)),
);

/// Set when the user taps "Skip for now" so the setup screen doesn't
/// reappear until the next app launch.
final aiSetupSkippedThisSessionProvider = StateProvider<bool>((ref) => false);
