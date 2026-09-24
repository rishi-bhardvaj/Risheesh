import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/url_helper.dart';
import '../../../shared/widgets/priority_chip.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/work_providers.dart';
import 'add_edit_project_dialog.dart';
import 'add_edit_task_dialog.dart';

class ProjectDetailsScreen extends ConsumerWidget {
  final Project? project;
  final String? projectId;

  const ProjectDetailsScreen({
    super.key,
    this.project,
    this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (project != null) {
      return _buildContent(context, ref, project!);
    }

    if (projectId != null) {
      final projectAsync = ref.watch(projectByIdProvider(projectId!));
      return projectAsync.when(
        data: (p) {
          if (p == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Project Details')),
              body: const Center(child: Text('Project not found')),
            );
          }
          return _buildContent(context, ref, p);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Project Details')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Project Details')),
          body: Center(child: Text('Error: $e')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Project Details')),
      body: const Center(child: Text('No project specified')),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Project p) {
    final theme = Theme.of(context);
    final status = ProjectStatus.fromString(p.status);
    final tasksAsync = ref.watch(tasksByProjectProvider(p.id));
    final tasks = tasksAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Project',
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => AddEditProjectDialog(existingProject: p),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Project',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Project?'),
                  content: Text('Delete "${p.name}"? This action cannot be undone.'),
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
                await ref.read(workRepositoryProvider).deleteProject(p.id);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.code, color: theme.colorScheme.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ProjectStatusBadge(status: status),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 14),

                    // Progress bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Completion Progress',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${(p.progress * 100).toInt()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: p.progress,
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),

                    if (p.deadline != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.event_outlined, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Target Deadline: ${DateFormatter.formatDate(p.deadline)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tech stack
            if (p.techStack != null && p.techStack!.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tech Stack',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: p.techStack!.split(',').map((tech) {
                          return Chip(
                            label: Text(tech.trim()),
                            backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            if (p.description != null && p.description!.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Highlights & Architecture',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Project Notes / Scratchpad
            if (p.notes != null && p.notes!.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Notes & Scratchpad',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.notes!,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Links (GitHub / Live Demo)
            if ((p.githubUrl != null && p.githubUrl!.isNotEmpty) || (p.liveUrl != null && p.liveUrl!.isNotEmpty)) ...[
              Row(
                children: [
                  if (p.githubUrl != null && p.githubUrl!.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.code, size: 18),
                        label: const Text('GitHub'),
                        onPressed: () => UrlHelper.launchURL(context, p.githubUrl),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (p.liveUrl != null && p.liveUrl!.isNotEmpty)
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.public, size: 18),
                        label: const Text('Live Demo'),
                        onPressed: () => UrlHelper.launchURL(context, p.liveUrl),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Associated Tasks Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.checklist, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Associated Tasks (${tasks.length})',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Task', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AddEditTaskDialog(initialProjectId: p.id),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    if (tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Text(
                            'No tasks associated with this project yet.',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final isDone = task.status.toLowerCase() == 'completed';
                          final priority = TaskPriority.fromString(task.priority);

                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AddEditTaskDialog(existingTask: task),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: isDone ? const Color(0xFF10B981) : theme.colorScheme.onSurface.withOpacity(0.5),
                                      size: 20,
                                    ),
                                    onPressed: () => ref.read(workRepositoryProvider).toggleTaskStatus(task),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            decoration: isDone ? TextDecoration.lineThrough : null,
                                            color: isDone ? theme.colorScheme.onSurface.withOpacity(0.5) : null,
                                          ),
                                        ),
                                        if (task.dueDate != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Due: ${DateFormatter.formatRelative(task.dueDate)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
