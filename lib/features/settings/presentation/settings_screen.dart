import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_keys.dart';
import '../../../core/constants/app_constants.dart';
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
                  'Your data stays in a local database on this phone. AI requests go directly from the phone to Anthropic, Google or NVIDIA using your own keys.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
