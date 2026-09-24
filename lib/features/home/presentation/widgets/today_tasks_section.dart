import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/priority_chip.dart';
import '../../../work/presentation/add_edit_task_dialog.dart';
import '../../../work/providers/work_providers.dart';

class TodayTasksSection extends ConsumerWidget {
  const TodayTasksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasks = ref.watch(todayTasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TODAY’S FOCUS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/work'),
              child: const Text('View All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (tasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No pending tasks for today!',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          'Add priority work items to stay in the zone.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const AddEditTaskDialog(),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('+ Task', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.take(4).length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final task = tasks[index];
              final priority = TaskPriority.fromString(task.priority);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.radio_button_unchecked, size: 22),
                        onPressed: () {
                          ref.read(workRepositoryProvider).toggleTaskStatus(task);
                        },
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            if (task.dueDate != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Due: ${DateFormatter.formatRelative(task.dueDate)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      PriorityChip(priority: priority),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

