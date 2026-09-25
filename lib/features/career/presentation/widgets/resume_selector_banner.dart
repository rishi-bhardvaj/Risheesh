import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../providers/career_providers.dart';

class ResumeSelectorBanner extends ConsumerWidget {
  const ResumeSelectorBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allResumesAsync = ref.watch(allResumesProvider);
    final selectionMode = ref.watch(resumeSelectionModeProvider);
    final activeResumes = ref.watch(activeResumesProvider);

    return allResumesAsync.when(
      data: (resumes) {
        if (resumes.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No resumes uploaded yet. Upload a resume in Resume Vault to enable instant matching & live discovery.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          );
        }

        String modeLabel = 'Default';
        switch (selectionMode) {
          case ResumeSelectionMode.single:
            modeLabel = activeResumes.isNotEmpty ? activeResumes.first.name : 'None Selected';
            break;
          case ResumeSelectionMode.multi:
            modeLabel = '${activeResumes.length} of ${resumes.length} Resumes Active';
            break;
          case ResumeSelectionMode.all:
            modeLabel = 'All Resumes (${resumes.length})';
            break;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.badge_outlined, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE RESUME CONTEXT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      modeLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Switch'),
                onPressed: () => _showResumeSelectionSheet(context, ref, resumes),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showResumeSelectionSheet(BuildContext context, WidgetRef ref, List<Resume> resumes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, child) {
            final currentMode = ref.watch(resumeSelectionModeProvider);
            final activeList = ref.watch(activeResumesProvider);
            final activeIds = activeList.map((r) => r.id).toSet();
            final theme = Theme.of(context);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Active Resume Context',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SegmentedButton<ResumeSelectionMode>(
                          segments: const [
                            ButtonSegment(
                              value: ResumeSelectionMode.single,
                              label: Text('Single'),
                            ),
                            ButtonSegment(
                              value: ResumeSelectionMode.multi,
                              label: Text('Multi'),
                            ),
                            ButtonSegment(
                              value: ResumeSelectionMode.all,
                              label: Text('All'),
                            ),
                          ],
                          selected: {currentMode},
                          onSelectionChanged: (set) {
                            if (set.isNotEmpty) {
                              ref.read(resumeSelectionModeProvider.notifier).state = set.first;
                            }
                          },
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Switching active resume updates job match calculation, recommendations, and search queries across Career OS.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const Divider(height: 24),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: resumes.length,
                        itemBuilder: (context, index) {
                          final resume = resumes[index];
                          final isSelected = activeIds.contains(resume.id);

                          return ListTile(
                            leading: Icon(
                              Icons.description_outlined,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                            ),
                            title: Text(
                              resume.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              'Target: ${resume.targetRole ?? "General"} • v${resume.version}',
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: currentMode == ResumeSelectionMode.single
                                ? Radio<String>(
                                    value: resume.id,
                                    groupValue: activeList.firstOrNull?.id,
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(singleSelectedResumeIdProvider.notifier).state = val;
                                        Navigator.pop(sheetContext);
                                      }
                                    },
                                  )
                                : Checkbox(
                                    value: isSelected,
                                    onChanged: currentMode == ResumeSelectionMode.all
                                        ? null
                                        : (checked) {
                                            final currentSelected = ref.read(multiSelectedResumeIdsProvider);
                                            final updated = Set<String>.from(currentSelected);
                                            if (checked == true) {
                                              updated.add(resume.id);
                                            } else {
                                              if (updated.length > 1) {
                                                updated.remove(resume.id);
                                              }
                                            }
                                            ref.read(multiSelectedResumeIdsProvider.notifier).state = updated;
                                          },
                                  ),
                            onTap: () {
                              if (currentMode == ResumeSelectionMode.single) {
                                ref.read(singleSelectedResumeIdProvider.notifier).state = resume.id;
                                Navigator.pop(sheetContext);
                              } else if (currentMode == ResumeSelectionMode.multi) {
                                final currentSelected = ref.read(multiSelectedResumeIdsProvider);
                                final updated = Set<String>.from(currentSelected);
                                if (updated.contains(resume.id)) {
                                  if (updated.length > 1) updated.remove(resume.id);
                                } else {
                                  updated.add(resume.id);
                                }
                                ref.read(multiSelectedResumeIdsProvider.notifier).state = updated;
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
