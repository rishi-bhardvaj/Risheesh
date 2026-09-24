import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/work_providers.dart';
import 'add_edit_task_dialog.dart';
import 'add_edit_work_note_dialog.dart';

class WorkNoteDetailsScreen extends ConsumerWidget {
  final WorkNote? note;
  final String? noteId;

  const WorkNoteDetailsScreen({super.key, this.note, this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (note != null) {
      return _buildContent(context, ref, note!);
    }

    if (noteId != null) {
      final noteAsync = ref.watch(workNoteByIdProvider(noteId!));
      return noteAsync.when(
        data: (n) {
          if (n == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Note Details')),
              body: const Center(child: Text('Note not found')),
            );
          }
          return _buildContent(context, ref, n);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Note Details')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Note Details')),
          body: Center(child: Text('Error: $e')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Note Details')),
      body: const Center(child: Text('No note specified')),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, WorkNote n) {
    final theme = Theme.of(context);
    final isMeeting = n.noteType.toLowerCase() == 'meeting';
    final actionItems = _parseActionItems(n.actionItems);

    return Scaffold(
      appBar: AppBar(
        title: Text(isMeeting ? 'Meeting Notes' : 'Work Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Note',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddEditWorkNoteDialog(existingNote: n),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Note',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Note?'),
                  content: Text('Are you sure you want to delete "${n.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(workRepositoryProvider).deleteWorkNote(n.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note deleted')),
                  );
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
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTypeBadge(n.noteType, theme),
                        const SizedBox(width: 8),
                        if (n.projectId != null)
                          _buildProjectBadge(ref, n.projectId!, theme),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      n.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: ${DateFormatter.formatDate(n.updatedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Meeting Details (If meeting note)
            if (isMeeting) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meeting Information',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (n.meetingDate != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 8),
                            Text(
                              'Date: ${DateFormatter.formatDate(n.meetingDate)}',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (n.participants != null && n.participants!.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.people_outline, size: 16, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Participants: ${n.participants}',
                                style: theme.textTheme.bodyMedium,
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
            ],

            // Content Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMeeting ? 'Notes & Discussion' : 'Content',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      n.content,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Items Section with One-Tap Task Conversion
            if (actionItems.isNotEmpty) ...[
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
                              const Icon(Icons.task_alt, size: 18, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Text(
                                'Action Items (${actionItems.length})',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: actionItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final itemText = actionItems[index];
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '• $itemText',
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.add_task, size: 14),
                                label: const Text('Convert to Task', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AddEditTaskDialog(
                                      initialProjectId: n.projectId,
                                      initialCategory: 'work',
                                      existingTask: null,
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _parseActionItems(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*')) {
            return line.substring(1).trim();
          }
          return line;
        })
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Widget _buildTypeBadge(String type, ThemeData theme) {
    Color bg;
    Color fg;
    String label;

    switch (type.toLowerCase()) {
      case 'meeting':
        bg = Colors.blue.withOpacity(0.15);
        fg = Colors.blue;
        label = 'Meeting Note';
        break;
      case 'technical':
        bg = Colors.purple.withOpacity(0.15);
        fg = Colors.purple;
        label = 'Technical Spec';
        break;
      case 'instruction':
        bg = Colors.orange.withOpacity(0.15);
        fg = Colors.orange;
        label = 'Runbook / Guide';
        break;
      case 'investigation':
        bg = Colors.red.withOpacity(0.15);
        fg = Colors.red;
        label = 'Investigation / Bug';
        break;
      default:
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.primary;
        label = 'General Note';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildProjectBadge(WidgetRef ref, String projectId, ThemeData theme) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));
    final projectName = projectAsync.valueOrNull?.name ?? 'Project';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_outlined, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(
            projectName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

