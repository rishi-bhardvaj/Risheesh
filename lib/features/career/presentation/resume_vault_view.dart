import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/resume_storage_helper.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../providers/career_providers.dart';
import 'add_edit_resume_dialog.dart';

class ResumeVaultView extends ConsumerWidget {
  const ResumeVaultView({super.key});

  Future<void> _deleteResume(BuildContext context, WidgetRef ref, Resume resume) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resume?'),
        content: Text('Are you sure you want to delete "${resume.name} (${resume.version})"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await db.deleteResume(resume.id);
      await ResumeStorageHelper.deleteResumeFile(resume.filePath);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume deleted from vault')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resumesAsync = ref.watch(allResumesProvider);

    return resumesAsync.when(
      data: (resumes) {
        if (resumes.isEmpty) {
          return EmptyStateView(
            icon: Icons.picture_as_pdf_outlined,
            title: 'No Resumes in Vault',
            message: 'Add your resume versions to keep them organized and linked to applications.',
            actionLabel: 'Add Resume',
            onAction: () {
              showDialog(
                context: context,
                builder: (_) => const AddEditResumeDialog(),
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: resumes.length,
          itemBuilder: (context, index) {
            final resume = resumes[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: resume.isPrimary ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                  width: resume.isPrimary ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      resume.name,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (resume.isPrimary)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star, color: Colors.amber, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'PRIMARY',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      resume.version,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (resume.targetRole != null) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Target: ${resume.targetRole!}',
                                        style: theme.textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'File: ${resume.fileName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (resume.notes != null && resume.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        resume.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Actions Bar
                    Row(
                      children: [
                        Text(
                          DateFormatter.formatDate(resume.updatedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.textTheme.labelSmall?.color?.withOpacity(0.5),
                          ),
                        ),
                        const Spacer(),
                        if (!resume.isPrimary)
                          TextButton.icon(
                            onPressed: () => ref.read(databaseProvider).setPrimaryResume(resume.id),
                            icon: const Icon(Icons.star_border, size: 16),
                            label: const Text('Set Primary', style: TextStyle(fontSize: 12)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit Details',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AddEditResumeDialog(resumeToEdit: resume),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: 'Delete',
                          onPressed: () => _deleteResume(context, ref, resume),
                        ),
                        const SizedBox(width: 4),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('Open'),
                          onPressed: () async {
                            final result = await ResumeStorageHelper.openResume(resume.filePath);
                            if (result.type != ResultType.done && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result.message)),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading resumes: $e')),
    );
  }
}
