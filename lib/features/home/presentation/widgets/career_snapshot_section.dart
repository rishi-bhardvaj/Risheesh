import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../career/presentation/application_details_screen.dart';
import '../../../career/providers/career_providers.dart';

class CareerSnapshotSection extends ConsumerWidget {
  const CareerSnapshotSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final snapshot = ref.watch(careerSnapshotProvider);
    final followUpsDue = ref.watch(followUpsDueTodayProvider);
    final recentJobs = ref.watch(allJobsProvider).valueOrNull ?? [];
    final recentApps = ref.watch(allApplicationsProvider).valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CAREER SNAPSHOT',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/career'),
              child: const Text('Open Career OS', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // 4-Card Quick Metrics Grid
        Row(
          children: [
            _buildMetricCard(
              context: context,
              title: 'Saved Jobs',
              count: snapshot.savedJobsCount.toString(),
              icon: Icons.bookmark_outline,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            _buildMetricCard(
              context: context,
              title: 'Active Apps',
              count: snapshot.activeApplicationsCount.toString(),
              icon: Icons.assignment_turned_in_outlined,
              color: Colors.indigo,
            ),
            const SizedBox(width: 8),
            _buildMetricCard(
              context: context,
              title: 'Interviews',
              count: snapshot.interviewsCount.toString(),
              icon: Icons.psychology_outlined,
              color: Colors.teal,
            ),
            const SizedBox(width: 8),
            _buildMetricCard(
              context: context,
              title: 'Offers',
              count: snapshot.offersCount.toString(),
              icon: Icons.emoji_events_outlined,
              color: Colors.amber.shade800,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Urgent Follow-up Alert (if any)
        if (followUpsDue.isNotEmpty) ...[
          Card(
            elevation: 0,
            color: Colors.redAccent.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${followUpsDue.length} Follow-up${followUpsDue.length > 1 ? "s" : ""} Due Today',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                        Text(
                          '${followUpsDue.first.role} @ ${followUpsDue.first.company}',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => context.push('/career/application/${followUpsDue.first.id}'),
                    child: const Text('Review'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Recent Applications Preview
        if (recentApps.isNotEmpty) ...[
          Text(
            'Recent Applications',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ...recentApps.take(2).map((app) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(app.role, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(app.company, style: const TextStyle(fontSize: 12)),
                  trailing: ApplicationStatusBadge(status: app.status),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ApplicationDetailsScreen(application: app)),
                    );
                  },
                ),
              )),
        ] else if (recentJobs.isNotEmpty) ...[
          Text(
            'Recent Opportunities',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ...recentJobs.take(2).map((job) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(job.company),
                  trailing: job.isSaved ? const Icon(Icons.bookmark, color: Colors.blue, size: 18) : null,
                  onTap: () => context.push('/career/job/${job.id}'),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              count,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
