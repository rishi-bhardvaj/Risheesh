import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Career OS'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.terminal_rounded,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.appTagline,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'v${AppConstants.appVersion}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Core Principles Section
          Text(
            'CORE ARCHITECTURAL PRINCIPLES',
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
                ListTile(
                  leading: Icon(Icons.offline_pin_outlined, color: theme.colorScheme.primary),
                  title: const Text('100% Offline-First'),
                  subtitle: const Text('All records, applications, tasks, and notes are persisted exclusively on-device in local SQLite storage.'),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.security_outlined, color: theme.colorScheme.primary),
                  title: const Text('Zero Telemetry & Full Privacy'),
                  subtitle: const Text('No analytics trackers, no third-party servers, and no background advertising SDKs.'),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.psychology_outlined, color: theme.colorScheme.primary),
                  title: const Text('Private Local AI Layer'),
                  subtitle: const Text('Integrated with user-controlled Ollama endpoints without sending queries to proprietary remote clouds.'),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.bolt_outlined, color: theme.colorScheme.primary),
                  title: const Text('Automation with User Consent'),
                  subtitle: const Text('Proactive deadline reminders and job deduplication requiring explicit confirmation for mutations.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tech Stack
          Text(
            'ENGINEERING & STACK',
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
                  leading: Icon(Icons.flutter_dash),
                  title: Text('Framework & Language'),
                  trailing: Text('Flutter 3.x / Dart 3.x', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.account_tree_outlined),
                  title: Text('State Management'),
                  trailing: Text('Riverpod 2.0', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.storage_outlined),
                  title: Text('Database Engine'),
                  trailing: Text('Drift 2.x + SQLite', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.palette_outlined),
                  title: Text('UI Design Language'),
                  trailing: Text('Material 3 Expressive', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Open Source Licenses
          Text(
            'LEGAL & OPEN SOURCE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Open Source Licenses'),
              subtitle: const Text('View licenses of third-party packages used'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion: 'v${AppConstants.appVersion}',
                  applicationLegalese: 'Crafted with passion for engineering productivity and career mastery.',
                );
              },
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
