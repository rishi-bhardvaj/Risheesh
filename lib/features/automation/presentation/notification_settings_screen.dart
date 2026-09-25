import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../automation/domain/automation_models.dart';
import '../providers/automation_providers.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(notificationSettingsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Controls'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          final effectiveSettings = settings ??
              NotificationSetting(
                id: 'default',
                careerEnabled: true,
                workEnabled: true,
                dsaEnabled: true,
                freelanceEnabled: true,
                projectsEnabled: true,
                weeklyReportsEnabled: true,
                eodReminderTime: '18:00',
                updatedAt: DateTime.now(),
              );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Local Notifications',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'On-device alerts for deadlines, follow-ups, and standup reminders.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'NOTIFICATION CATEGORIES',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.work_outline, color: Colors.blue),
                      title: const Text('Career & Job Follow-ups'),
                      subtitle: const Text('Alerts when job application follow-ups are due'),
                      value: effectiveSettings.careerEnabled,
                      onChanged: (val) => _updateSettings(effectiveSettings.copyWith(careerEnabled: val)),
                    ),
                    const Divider(),
                    SwitchListTile(
                      secondary: const Icon(Icons.alarm, color: Colors.amber),
                      title: const Text('Work Task Deadlines'),
                      subtitle: const Text('Alerts for work tasks due today or overdue'),
                      value: effectiveSettings.workEnabled,
                      onChanged: (val) => _updateSettings(effectiveSettings.copyWith(workEnabled: val)),
                    ),
                    const Divider(),
                    SwitchListTile(
                      secondary: const Icon(Icons.psychology, color: Colors.purple),
                      title: const Text('DSA Spaced Repetition'),
                      subtitle: const Text('Prompts to review problems scheduled for today'),
                      value: effectiveSettings.dsaEnabled,
                      onChanged: (val) => _updateSettings(effectiveSettings.copyWith(dsaEnabled: val)),
                    ),
                    const Divider(),
                    SwitchListTile(
                      secondary: const Icon(Icons.handshake_outlined, color: Colors.green),
                      title: const Text('Freelance Pipeline Follow-ups'),
                      subtitle: const Text('Alerts when client leads require follow-up'),
                      value: effectiveSettings.freelanceEnabled,
                      onChanged: (val) => _updateSettings(effectiveSettings.copyWith(freelanceEnabled: val)),
                    ),
                    const Divider(),
                    SwitchListTile(
                      secondary: const Icon(Icons.assessment_outlined, color: Colors.teal),
                      title: const Text('Weekly Digest Summary'),
                      subtitle: const Text('Prompts when weekly report is generated'),
                      value: effectiveSettings.weeklyReportsEnabled,
                      onChanged: (val) => _updateSettings(effectiveSettings.copyWith(weeklyReportsEnabled: val)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'DAILY STANDUP REMINDER TIME',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.edit_note, color: Colors.deepOrange),
                  title: const Text('End-Of-Day (EOD) Reminder'),
                  subtitle: Text('Current time: ${effectiveSettings.eodReminderTime}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _pickEODTime(effectiveSettings),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.notifications_none),
                label: const Text('Send Test Notification'),
                onPressed: () async {
                  final notifService = ref.read(notificationServiceProvider);
                  await notifService.showNotification(
                    id: 999,
                    title: 'Test Notification',
                    body: 'Career OS notification engine is functioning properly.',
                    category: NotificationCategory.career,
                    settings: effectiveSettings,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test notification dispatched!')),
                    );
                  }
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading settings: $err')),
      ),
    );
  }

  Future<void> _updateSettings(NotificationSetting updated) async {
    final db = ref.read(databaseProvider);
    await db.upsertNotificationSettings(NotificationSettingsCompanion(
      id: const drift.Value('default'),
      careerEnabled: drift.Value(updated.careerEnabled),
      workEnabled: drift.Value(updated.workEnabled),
      dsaEnabled: drift.Value(updated.dsaEnabled),
      freelanceEnabled: drift.Value(updated.freelanceEnabled),
      projectsEnabled: drift.Value(updated.projectsEnabled),
      weeklyReportsEnabled: drift.Value(updated.weeklyReportsEnabled),
      eodReminderTime: drift.Value(updated.eodReminderTime),
      updatedAt: drift.Value(DateTime.now()),
    ));
  }

  Future<void> _pickEODTime(NotificationSetting settings) async {
    final parts = settings.eodReminderTime.split(':');
    final initialHour = int.tryParse(parts[0]) ?? 18;
    final initialMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await _updateSettings(settings.copyWith(eodReminderTime: formatted));
    }
  }
}
