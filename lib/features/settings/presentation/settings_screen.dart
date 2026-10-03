import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_keys.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import 'edit_profile_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeNotifierProvider);
    final profile = ref.watch(userProfileStreamProvider).valueOrNull;
    final keys = ref.watch(aiKeysProvider);
    final connected = AiProvider.values.where(keys.has).map((p) => p.label).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AppCard(
            onTap: () => showDialog(context: context, builder: (_) => EditProfileDialog(currentProfile: profile)),
            child: Row(
              children: [
                InitialAvatar(name: profile?.name ?? 'Me', size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.name ?? 'Set up your profile', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        [profile?.currentRole, if ((profile?.experienceYears ?? 0) > 0) '${profile!.experienceYears} yrs'].whereType<String>().join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined),
              ],
            ),
          ),
          const SectionHeader(title: 'AI', padding: EdgeInsets.fromLTRB(4, 20, 4, 8)),
          AppCard(
            onTap: () => context.push('/settings/ai'),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppTheme.accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI keys', style: theme.textTheme.titleSmall),
                      Text(connected.isEmpty ? 'Not connected' : 'Connected: ${connected.join(', ')}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (!keys.hasRequired) const Tag('Action needed', color: AppTheme.warning),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SectionHeader(title: 'Backend Server', padding: EdgeInsets.fromLTRB(4, 20, 4, 8)),
          AppCard(
            onTap: () => _showServerUrlDialog(context, ref),
            child: Row(
              children: [
                const Icon(Icons.cloud_sync_rounded, color: AppTheme.accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Server URL', style: theme.textTheme.titleSmall),
                      Text(
                        ref.watch(sharedPreferencesProvider).getString('custom_backend_url') ?? ApiConfig.baseUrl,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined),
              ],
            ),
          ),
          const SectionHeader(title: 'Appearance', padding: EdgeInsets.fromLTRB(4, 20, 4, 8)),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
              ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.phone_android_rounded)),
            ],
            selected: {mode},
            onSelectionChanged: (s) => ref.read(themeNotifierProvider.notifier).setThemeMode(s.first),
          ),
          const SectionHeader(title: 'About', padding: EdgeInsets.fromLTRB(4, 20, 4, 8)),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.appName, style: theme.textTheme.titleSmall),
                Text('Version ${AppConstants.appVersion}', style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(
                  'Your data is stored in the local reactive cache and synchronized with the backend. AI requests go directly using your own keys (Google Gemini, NVIDIA) or local Ollama.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showServerUrlDialog(BuildContext context, WidgetRef ref) {
    final prefs = ref.read(sharedPreferencesProvider);
    final current = prefs.getString('custom_backend_url') ?? ApiConfig.baseUrl;
    final controller = TextEditingController(text: current);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend Server URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your deployed backend URL. Live jobs, applications, and freelance data sync with this server.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://risheesh-backend.onrender.com',
                prefixIcon: Icon(Icons.link_rounded),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.remove('custom_backend_url');
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Reset Default'),
          ),
          FilledButton(
            onPressed: () async {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                await prefs.setString('custom_backend_url', val);
              } else {
                await prefs.remove('custom_backend_url');
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
