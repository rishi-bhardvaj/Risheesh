import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_clients.dart';
import '../../../core/ai/ai_keys.dart';
import '../../../core/ai/ai_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/url_helper.dart';
import '../../../shared/widgets/ui_kit.dart';

/// Collects the Claude, Gemini and (optional) NVIDIA keys. Shown on launch
/// while a required key is missing, and from Settings.
class AiKeysScreen extends ConsumerWidget {
  final bool firstRun;

  const AiKeysScreen({super.key, this.firstRun = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(aiKeysProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: firstRun ? null : AppBar(title: const Text('AI keys')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            if (firstRun) ...[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accent, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Connect your AI', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
            ],
            Text(
              'Keys are stored encrypted on this phone (Android Keystore) and are only sent to their own provider.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            for (final p in AiProvider.values) ...[
              _KeyCard(provider: p, isSet: keys.has(p)),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            if (firstRun) ...[
              FilledButton(
                onPressed: keys.hasRequired ? () => context.go('/home') : null,
                child: const Text('Continue'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  ref.read(aiSetupSkippedThisSessionProvider.notifier).state = true;
                  context.go('/home');
                },
                child: Text('Skip for now', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeyCard extends ConsumerStatefulWidget {
  final AiProvider provider;
  final bool isSet;

  const _KeyCard({required this.provider, required this.isSet});

  @override
  ConsumerState<_KeyCard> createState() => _KeyCardState();
}

class _KeyCardState extends ConsumerState<_KeyCard> {
  final _controller = TextEditingController();
  bool _editing = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _model;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final model = await ref.read(aiServiceProvider).verify(widget.provider, key);
      await ref.read(aiKeysProvider.notifier).set(widget.provider, key);
      setState(() {
        _model = model;
        _editing = false;
        _controller.clear();
      });
    } on AiException catch (e) {
      setState(() => _error = e.isAuth ? 'Key was rejected. Check it and try again.' : e.message);
    } catch (e) {
      setState(() => _error = 'Could not verify: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.provider;
    final showField = _editing || !widget.isSet;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(p.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              if (widget.isSet)
                const Tag('Connected', color: AppTheme.success, icon: Icons.check_rounded)
              else
                Tag(p.required ? 'Required' : 'Optional', color: p.required ? AppTheme.warning : null),
            ],
          ),
          const SizedBox(height: 4),
          Text(p.purpose, style: theme.textTheme.bodySmall),
          if (_model != null) ...[
            const SizedBox(height: 4),
            Text('Using $_model', style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.success)),
          ],
          if (showField) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                hintText: '${p.keyPrefix}…',
                errorText: _error,
                errorMaxLines: 3,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Paste',
                      icon: const Icon(Icons.content_paste_rounded, size: 20),
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) setState(() => _controller.text = data!.text!.trim());
                      },
                    ),
                    IconButton(
                      tooltip: _obscure ? 'Show' : 'Hide',
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ],
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => UrlHelper.launchURL(context, p.keyUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Get a key'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Verify & save'),
                ),
              ],
            ),
          ] else
            Row(
              children: [
                TextButton(onPressed: () => setState(() => _editing = true), child: const Text('Replace key')),
                TextButton(
                  onPressed: () => ref.read(aiKeysProvider.notifier).set(p, null),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                  child: const Text('Remove'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
