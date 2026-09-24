import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../work/presentation/project_details_screen.dart';
import '../../../work/providers/work_providers.dart';

class ProjectsSnapshotSection extends ConsumerWidget {
  const ProjectsSnapshotSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsStreamProvider);
    final projects = (projectsAsync.value ?? [])
        .where((p) => p.status == 'in_progress' || p.status == 'planned')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE PROJECTS',
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
        if (projects.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No active projects',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          'Track personal engineering projects and portfolio items.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: projects.take(2).length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final project = projects[index];
              final status = ProjectStatus.fromString(project.status);

              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProjectDetailsScreen(project: project)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              project.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            ProjectStatusBadge(status: status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (project.techStack != null && project.techStack!.isNotEmpty)
                              Expanded(
                                child: Text(
                                  project.techStack!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              )
                            else
                              const Spacer(),
                            Text(
                              '${(project.progress * 100).toInt()}%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: project.progress,
                            minHeight: 4,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

