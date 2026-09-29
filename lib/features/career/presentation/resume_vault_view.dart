import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/resume_storage_helper.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/feed_widgets.dart';
import '../providers/career_providers.dart';
import 'add_edit_resume_dialog.dart';
import 'widgets/ats_report_sheet.dart';
import 'widgets/paste_resume_dialog.dart';

class ResumeVaultView extends ConsumerWidget {
  const ResumeVaultView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumesAsync = ref.watch(allResumesProvider);

    return resumesAsync.when(
      data: (resumes) {
        if (resumes.isEmpty) {
          return EmptyStateView(
            icon: Icons.description_outlined,
            title: 'No resumes yet',
            message: 'Upload a PDF, DOCX or TXT resume to get an ATS score, keyword gaps against live jobs, and an auto-filled profile.',
            actionLabel: 'Add resume',
            onAction: () => showDialog(context: context, builder: (_) => const AddEditResumeDialog()),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          itemCount: resumes.length,
          itemBuilder: (context, i) => ResumeCard(resume: resumes[i]),
        );
      },
      loading: () => ListView(padding: const EdgeInsets.all(16), children: const [SkeletonCard(), SkeletonCard()]),
      error: (e, _) => Center(child: Text('Error loading resumes: $e')),
    );
  }
}

class ResumeCard extends ConsumerWidget {
  final Resume resume;

  const ResumeCard({super.key, required this.resume});

  Future<void> _parse(BuildContext context, WidgetRef ref, {String? pastedText}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(resumeParsingProvider.notifier).parse(resume, pastedText: pastedText);
      final p = result.profile;
      messenger.showSnackBar(SnackBar(
        content: Text('Parsed ${p.allUniqueSkills.length} skills and ${p.experience.length} roles${p.fullName != null ? ' for ${p.fullName!.value}' : ''}'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e'), duration: const Duration(seconds: 6)));
    }
  }

  Future<void> _paste(BuildContext context, WidgetRef ref) async {
    final text = await showPasteResumeDialog(context);
    if (text != null && context.mounted) await _parse(context, ref, pastedText: text);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete resume?'),
        content: Text('“${resume.name} (${resume.version})” will be removed from the vault.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(databaseProvider).deleteResume(resume.id);
    await ResumeStorageHelper.deleteResumeFile(resume.filePath);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resume deleted')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final parsing = ref.watch(resumeParsingProvider).contains(resume.id);
    final report = ref.watch(atsReportProvider((resumeId: resume.id, jobId: null)));
    final profile = ref.watch(parsedResumeProfilesProvider)[resume.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: resume.isPrimary ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: resume.isPrimary ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.description_rounded, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(resume.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          MetaChip(label: resume.version),
                          if (resume.isPrimary) const MetaChip(label: 'Primary', icon: Icons.star_rounded, color: AppTheme.warning),
                          if (resume.targetRole != null) MetaChip(label: resume.targetRole!, icon: Icons.flag_outlined),
                          MetaChip(label: resume.fileName, icon: Icons.attach_file_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (parsing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [LinearProgressIndicator(), SizedBox(height: 6), Text('Reading resume…')],
                ),
              )
            else if (report != null && profile != null)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => showAtsReportSheet(context, resume),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      AtsScoreRing(score: report.total),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ATS score · ${report.grade}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            Text(
                              '${profile.allUniqueSkills.length} skills · ${profile.experience.length} roles'
                              '${report.suggestions.isEmpty ? '' : ' · ${report.suggestions.length} tips'}',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              )
            else if (resume.extractionStatus == 'FAILED')
              StatusBanner(
                tone: BannerTone.warning,
                title: 'Couldn’t read this file',
                message: 'Scanned or protected PDFs have no text layer. Paste the text instead.',
                onRetry: () => _parse(context, ref),
                onDetails: () => _paste(context, ref),
                detailsLabel: 'Paste text',
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _parse(context, ref),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Parse & score'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _paste(context, ref),
                    icon: const Icon(Icons.content_paste_rounded, size: 18),
                    label: const Text('Paste text'),
                  ),
                ],
              ),
            const Divider(height: 20),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 4,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 8),
                  child: Text(
                    'Updated ${DateFormatter.formatDate(resume.updatedAt)}',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!resume.isPrimary)
                      IconButton(
                        tooltip: 'Set as primary',
                        icon: const Icon(Icons.star_border_rounded),
                        onPressed: () => ref.read(databaseProvider).setPrimaryResume(resume.id),
                      ),
                    if (profile != null && !parsing)
                      IconButton(
                        tooltip: 'Re-parse',
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () => _parse(context, ref),
                      ),
                    IconButton(
                      tooltip: 'Edit details',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => showDialog(context: context, builder: (_) => AddEditResumeDialog(resumeToEdit: resume)),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _delete(context, ref),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Open'),
                      onPressed: () async {
                        final result = await ResumeStorageHelper.openResume(resume.filePath);
                        if (result.type != ResultType.done && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
