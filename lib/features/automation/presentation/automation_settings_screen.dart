import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/automation_providers.dart';
import 'widgets/automation_run_result_dialog.dart';

class AutomationSettingsScreen extends ConsumerWidget {
  const AutomationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(automationRulesStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Run History Log',
            onPressed: () => _showHistorySheet(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Run All Enabled Rules Now',
            onPressed: () => _runAllRules(context, ref),
          ),
        ],
      ),
      body: rulesAsync.when(
        data: (rules) {
          if (rules.isEmpty) {
            return Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Initialize Default Automation Rules'),
                onPressed: () async {
                  await ref.read(automationEngineProvider).initialize();
                },
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.bolt, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Proactive Career Intelligence',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Background evaluators detect deadlines, follow-ups, and RSS jobs without autonomous destructive actions.',
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
                'AUTOMATION EVALUATION RULES',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              ...rules.map((rule) => _buildRuleCard(context, ref, rule, theme)),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading rules: $err')),
      ),
    );
  }

  Widget _buildRuleCard(
    BuildContext context,
    WidgetRef ref,
    AutomationRule rule,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.name,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rule.description ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: rule.enabled,
                  onChanged: (enabled) async {
                    await ref.read(databaseProvider).toggleAutomationRuleEnabled(rule.id, enabled);
                  },
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rule.schedule,
                        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(rule.status, theme),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Run Now'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => _runSingleRule(context, ref, rule),
                ),
              ],
            ),
            if (rule.lastRun != null) ...[
              const SizedBox(height: 6),
              Text(
                'Last executed: ${_formatDateTime(rule.lastRun!)}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme) {
    Color color;
    switch (status) {
      case 'SUCCESS':
        color = Colors.green;
        break;
      case 'RUNNING':
        color = Colors.blue;
        break;
      case 'FAILED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _runSingleRule(BuildContext context, WidgetRef ref, AutomationRule rule) async {
    final engine = ref.read(automationEngineProvider);
    final result = await engine.runAutomation(rule.id);
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AutomationRunResultDialog(result: result, title: 'Executed: ${rule.name}'),
      );
    }
  }

  Future<void> _runAllRules(BuildContext context, WidgetRef ref) async {
    final engine = ref.read(automationEngineProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Executing all enabled rules...')),
    );
    final results = await engine.runAllEnabledRules();
    if (context.mounted) {
      final totalEvaluated = results.fold<int>(0, (s, r) => s + r.itemsEvaluated);
      final totalCreated = results.fold<int>(0, (s, r) => s + r.itemsCreated);
      final totalActions = results.fold<int>(0, (s, r) => s + r.proposedActions.length);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Finished ${results.length} rules. Evaluated: $totalEvaluated, Created: $totalCreated, Actions: $totalActions'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showHistorySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final runsAsync = ref.watch(recentRunsStreamProvider);
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (_, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Automation Execution Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),
                    runsAsync.when(
                      data: (runs) {
                        if (runs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: Text('No execution logs recorded yet.')),
                          );
                        }

                        return Column(
                          children: runs.map((run) => ListTile(
                            leading: Icon(
                              run.status == 'SUCCESS' ? Icons.check_circle : Icons.error_outline,
                              color: run.status == 'SUCCESS' ? Colors.green : Colors.red,
                            ),
                            title: Text('Run ID: ${run.id.substring(0, 8)}... (${run.automationId})'),
                            subtitle: Text(run.errorMessage ?? 'Processed ${run.itemsProcessed} items, created ${run.itemsCreated} items'),
                            trailing: Text(
                              '${run.startedAt.hour.toString().padLeft(2, '0')}:${run.startedAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          )).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
