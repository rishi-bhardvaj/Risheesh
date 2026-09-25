import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/track_providers.dart';
import 'add_edit_dsa_dialog.dart';

class DSAProblemDetailsScreen extends ConsumerWidget {
  final DSAProblem? problem;
  final String? problemId;

  const DSAProblemDetailsScreen({
    super.key,
    this.problem,
    this.problemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final id = problem?.id ?? problemId;

    if (id == null) {
      return const Scaffold(body: Center(child: Text('Invalid problem ID.')));
    }

    final problemAsync = ref.watch(dsaProblemByIdProvider(id));
    final currentProblem = problemAsync.valueOrNull ?? problem;

    if (currentProblem == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('DSA Problem')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final diff = DSADifficulty.fromString(currentProblem.difficulty);
    final status = DSAStatus.fromString(currentProblem.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Problem Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Problem',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddEditDSADialog(problemToEdit: currentProblem),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Problem',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Problem?'),
                  content: Text('Are you sure you want to delete "${currentProblem.title}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(trackRepositoryProvider).deleteDSAProblem(currentProblem.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main Header Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentProblem.title,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    currentProblem.platform,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    currentProblem.topic,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildDifficultyBadge(diff),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Status and Revision Row
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _buildInfoTile('Status', status.label, Icons.check_circle_outline, theme),
                      _buildInfoTile('Attempts', '${currentProblem.attempts}', Icons.refresh, theme),
                      if (currentProblem.solvedAt != null)
                        _buildInfoTile('Solved Date', DateFormatter.formatDate(currentProblem.solvedAt), Icons.event_available, theme),
                      if (currentProblem.revisionDate != null)
                        _buildInfoTile('Revision Due', DateFormatter.formatDate(currentProblem.revisionDate), Icons.alarm, theme),
                    ],
                  ),

                  if (currentProblem.url != null && currentProblem.url!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Open in Browser'),
                        onPressed: () async {
                          final uri = Uri.tryParse(currentProblem.url!);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Quick Buttons Bar
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: Text(status == DSAStatus.solved ? 'Solved' : 'Mark Solved'),
                  onPressed: () async {
                    await ref.read(trackRepositoryProvider).recordDSAAttempt(currentProblem, solved: true);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('+1 Attempt'),
                  onPressed: () async {
                    await ref.read(trackRepositoryProvider).recordDSAAttempt(currentProblem, solved: false);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.alarm, size: 18),
            label: Text(currentProblem.revisionDate != null
                ? 'Reschedule Revision (${DateFormatter.formatDate(currentProblem.revisionDate)})'
                : 'Schedule Revision Date'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: currentProblem.revisionDate ?? DateTime.now().add(const Duration(days: 3)),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                await ref.read(trackRepositoryProvider).setDSARevisionDate(currentProblem.id, picked);
              }
            },
          ),
          const SizedBox(height: 16),

          // Solution / Approach Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'SOLUTION & APPROACH',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    (currentProblem.solution != null && currentProblem.solution!.trim().isNotEmpty)
                        ? currentProblem.solution!
                        : 'No approach or algorithm notes logged yet. Tap Edit to add space-time complexity and key insights.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: (currentProblem.solution != null && currentProblem.solution!.trim().isNotEmpty)
                          ? theme.colorScheme.onSurface
                          : theme.hintColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Personal Notes Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'PERSONAL NOTES & MISTAKES',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    (currentProblem.notes != null && currentProblem.notes!.trim().isNotEmpty)
                        ? currentProblem.notes!
                        : 'No personal notes logged.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: (currentProblem.notes != null && currentProblem.notes!.trim().isNotEmpty)
                          ? theme.colorScheme.onSurface
                          : theme.hintColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(DSADifficulty diff) {
    Color color;
    switch (diff) {
      case DSADifficulty.easy:
        color = Colors.green;
        break;
      case DSADifficulty.medium:
        color = Colors.orange.shade800;
        break;
      case DSADifficulty.hard:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        diff.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 10, color: theme.hintColor)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
