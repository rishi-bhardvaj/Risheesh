import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/app_database.dart';
import '../../providers/automation_providers.dart';

class NeedsAttentionCard extends ConsumerWidget {
  const NeedsAttentionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingActionsAsync = ref.watch(pendingActionsStreamProvider);
    final theme = Theme.of(context);

    return pendingActionsAsync.when(
      data: (actions) {
        if (actions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Needs Attention (${actions.length})',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/settings/automation'),
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      child: const Text('Automation'),
                    ),
                  ],
                ),
                const Divider(height: 20),
                ...actions.take(3).map((action) => _buildActionItem(context, ref, action, theme)),
                if (actions.length > 3) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '+ ${actions.length - 3} more items pending',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    WidgetRef ref,
    AutomationAction action,
    ThemeData theme,
  ) {
    const urgencyColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: urgencyColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: urgencyColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getIconForAction(action.actionType), size: 18, color: urgencyColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  action.description,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 18),
            tooltip: 'Resolve',
            onPressed: () {
              ref.read(automationActionsNotifierProvider.notifier).resolveAction(action.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Dismiss',
            onPressed: () {
              ref.read(automationActionsNotifierProvider.notifier).dismissAction(action.id);
            },
          ),
        ],
      ),
    );
  }

  IconData _getIconForAction(String actionType) {
    switch (actionType) {
      case 'APPLICATION_FOLLOWUP':
        return Icons.send_time_extension_outlined;
      case 'WORK_TASK_DEADLINE':
        return Icons.alarm;
      case 'EOD_MISSING':
        return Icons.edit_note;
      case 'DSA_REVISION_DUE':
        return Icons.psychology;
      case 'FREELANCE_FOLLOWUP':
        return Icons.handshake_outlined;
      case 'PROJECT_DEADLINE':
        return Icons.event_busy;
      case 'JOB_MATCH':
        return Icons.work_outline;
      default:
        return Icons.info_outline;
    }
  }
}
