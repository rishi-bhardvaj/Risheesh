import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/url_helper.dart';
import '../providers/career_providers.dart';
import 'add_edit_application_dialog.dart';
import 'add_edit_job_dialog.dart';

class JobDetailsScreen extends ConsumerWidget {
  final Job? job;
  final String? jobId;

  const JobDetailsScreen({
    super.key,
    this.job,
    this.jobId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (job != null) {
      return _buildContent(context, ref, job!);
    }

    if (jobId != null) {
      final jobAsync = ref.watch(jobByIdProvider(jobId!));
      return jobAsync.when(
        data: (j) {
          if (j == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Job Details')),
              body: const Center(child: Text('Job not found')),
            );
          }
          return _buildContent(context, ref, j);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Job Details')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Job Details')),
          body: Center(child: Text('Error: $e')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: const Center(child: Text('No job specified')),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Job j) {
    final theme = Theme.of(context);
    final match = ref.watch(jobMatchProvider(j));
    final linkedAppAsync = ref.watch(jobApplicationByJobIdProvider(j.id));
    final linkedApp = linkedAppAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(
            icon: Icon(
              j.isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: j.isSaved ? theme.colorScheme.primary : null,
            ),
            tooltip: j.isSaved ? 'Saved' : 'Save Job',
            onPressed: () {
              ref.read(careerRepositoryProvider).toggleJobSaved(j.id, !j.isSaved);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Job',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddEditJobDialog(existingJob: j),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Job',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Job?'),
                  content: Text('Are you sure you want to delete "${j.title}" at ${j.company}?'),
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
                await ref.read(careerRepositoryProvider).deleteJob(j.id);
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      j.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      j.company,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (j.location != null)
                          _buildMetaChip(Icons.location_on_outlined, j.location!, theme),
                        if (j.employmentType != null)
                          _buildMetaChip(Icons.work_outline, j.employmentType!, theme),
                        if (j.salary != null)
                          _buildMetaChip(Icons.payments_outlined, j.salary!, theme),
                        if (j.experienceRequirement != null)
                          _buildMetaChip(Icons.timer_outlined, j.experienceRequirement!, theme),
                        if (j.source != null)
                          _buildMetaChip(Icons.source_outlined, j.source!, theme),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Heuristic Match Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Profile Alignment', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: match.matchPercentage >= 70
                                ? Colors.green.withOpacity(0.15)
                                : (match.matchPercentage >= 40 ? Colors.orange.withOpacity(0.15) : Colors.grey.withOpacity(0.15)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${match.matchPercentage}% Match',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: match.matchPercentage >= 70
                                  ? Colors.green.shade800
                                  : (match.matchPercentage >= 40 ? Colors.orange.shade900 : Colors.grey.shade700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (match.matchingFactors.isNotEmpty) ...[
                      Text('Matching Criteria', style: theme.textTheme.labelMedium?.copyWith(color: Colors.green.shade800)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: match.matchingFactors.map((f) => Chip(
                          label: Text(f, style: TextStyle(fontSize: 11, color: Colors.green.shade900)),
                          backgroundColor: Colors.green.withOpacity(0.1),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        )).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (match.gapFactors.isNotEmpty) ...[
                      Text('Missing / Potential Gaps', style: theme.textTheme.labelMedium?.copyWith(color: Colors.orange.shade800)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: match.gapFactors.map((g) => Chip(
                          label: Text(g, style: TextStyle(fontSize: 11, color: Colors.orange.shade900)),
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Skills Card
            if (j.skills != null && j.skills!.isNotEmpty) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Key Skills & Requirements', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: j.skills!.split(RegExp(r'[,/|]')).map((s) => s.trim()).where((s) => s.isNotEmpty).map((skill) {
                          return Chip(
                            label: Text(skill, style: const TextStyle(fontSize: 12)),
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
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

            // Job Description
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Job Description', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SelectableText(
                      j.description != null && j.description!.isNotEmpty ? j.description! : 'No description provided.',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Personal Notes
            if (j.notes != null && j.notes!.isNotEmpty) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Internal Notes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SelectableText(j.notes!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Bottom Actions
            Row(
              children: [
                if (j.url != null && j.url!.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open URL'),
                      onPressed: () => UrlHelper.launchURL(context, j.url),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    icon: Icon(linkedApp != null ? Icons.visibility : Icons.send),
                    label: Text(linkedApp != null ? 'View Application' : 'Track Application'),
                    onPressed: () {
                      if (linkedApp != null) {
                        context.push('/career/application/${linkedApp.id}');
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => AddEditApplicationDialog(initialJob: j),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
