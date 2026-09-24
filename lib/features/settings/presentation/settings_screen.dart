import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import 'edit_profile_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeNotifierProvider);
    final profileAsync = ref.watch(userProfileStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Card
          Text(
            'PROFILE & CAREER',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No profile found.'),
                  ),
                );
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'E',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              profile.currentRole ?? 'Software Engineer',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => EditProfileDialog(currentProfile: profile),
                        ),
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading profile: $e'),
          ),
          const SizedBox(height: 24),

          // Appearance Section
          Text(
            'APPEARANCE & THEME',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('System Default'),
                  subtitle: const Text('Follow system dark/light mode'),
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeNotifierProvider.notifier).setThemeMode(mode);
                    }
                  },
                ),
                const Divider(),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Deep developer dark theme'),
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeNotifierProvider.notifier).setThemeMode(mode);
                    }
                  },
                ),
                const Divider(),
                RadioListTile<ThemeMode>(
                  title: const Text('Light Mode'),
                  subtitle: const Text('Crisp clean daylight theme'),
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeNotifierProvider.notifier).setThemeMode(mode);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Local Persistence & Backup
          Text(
            'LOCAL PERSISTENCE & DATA',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.storage_outlined),
                  title: Text('Local SQLite Engine'),
                  subtitle: Text('All tasks, jobs, apps, and projects stored on-device via Drift + SQLite'),
                  trailing: Icon(Icons.check_circle, color: Colors.green, size: 20),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Export Personal Data (JSON)'),
                  subtitle: const Text('Export full database backup (Scheduled in Phase 7)'),
                  trailing: const Icon(Icons.lock_outline, size: 18),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Full JSON export pipeline will be activated in Phase 7')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About App
          Text(
            'ABOUT',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.terminal),
                  title: Text(AppConstants.appName),
                  subtitle: Text(AppConstants.appTagline),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  trailing: Text(
                    AppConstants.appVersion,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
