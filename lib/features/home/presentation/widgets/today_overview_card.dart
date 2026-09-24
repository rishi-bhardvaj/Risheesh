import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../career/providers/career_providers.dart';
import '../../../work/providers/work_providers.dart';

class TodayOverviewCard extends ConsumerWidget {
  const TodayOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final taskSummary = ref.watch(taskSummaryProvider);
    final careerSnapshot = ref.watch(careerSnapshotProvider);
    final workSnapshot = ref.watch(workSnapshotProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TODAY’S OVERVIEW',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  '${taskSummary.completed}/${taskSummary.total} tasks done',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.checklist_rtl_outlined,
                    count: '${taskSummary.pending}',
                    label: 'Pending Tasks',
                    color: theme.colorScheme.primary,
                    onTap: () => context.go('/work'),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.bookmark_outline,
                    count: '${careerSnapshot.savedJobsCount}',
                    label: 'Saved Jobs',
                    color: const Color(0xFF38BDF8),
                    onTap: () => context.go('/career'),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.alarm,
                    count: '${careerSnapshot.followUpsDueCount}',
                    label: 'Follow-ups Due',
                    color: careerSnapshot.followUpsDueCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    onTap: () => context.go('/career'),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.folder_outlined,
                    count: '${workSnapshot.activeProjectsCount}',
                    label: 'Active Projects',
                    color: const Color(0xFFF59E0B),
                    onTap: () => context.go('/work'),
                    theme: theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String count,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              count,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
