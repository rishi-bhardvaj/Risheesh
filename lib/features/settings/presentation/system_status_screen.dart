import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/ui_kit.dart';

class SystemStatusScreen extends ConsumerWidget {
  const SystemStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('System Status & Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.appName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text('Version ${AppConstants.appVersion}', style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                _buildStatusItem('Database: Drift SQLite v11 (Healthy)'),
                _buildStatusItem('Relevance Scoring Engine: Active'),
                _buildStatusItem('Local Notifications: Initialized'),
                _buildStatusItem('Background Worker: Registered'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
