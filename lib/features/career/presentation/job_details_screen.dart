import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_service.dart';
import '../../../core/ai/document_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/url_helper.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../providers/career_providers.dart';
import 'add_edit_job_dialog.dart';

class JobDetailsScreen extends ConsumerWidget {
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(jobByIdProvider(jobId)).valueOrNull;
    if (job == null) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    final theme = Theme.of(context);
    final match = ref.watch(jobMatchProvider(job));
    final application = ref.watch(jobApplicationByJobIdProvider(job.id)).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: job.isSaved ? 'Unsave' : 'Save',
            onPressed: () => ref.read(databaseProvider).toggleJobSaved(job.id, !job.isSaved),
            icon: Icon(job.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: job.isSaved ? AppTheme.accent : null),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                showDialog(context: context, builder: (_) => AddEditJobDialog(jobToEdit: job));
              } else if (v == 'delete') {
                await ref.read(careerRepositoryProvider).deleteJob(job.id);
                if (context.mounted) context.pop();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              if (application == null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(careerRepositoryProvider).convertJobToApplication(
                          job: job,
                          status: ApplicationStatus.applied,
                          appliedAt: DateTime.now(),
                          followUpDate: DateTime.now().add(const Duration(days: 7)),
                        ),
                    child: const Text('Mark as applied'),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/career/application/${application.id}'),
                    child: Text('Applied · ${ApplicationStatus.fromString(application.status).label}'),
                  ),
                ),
              if (job.url != null && job.url!.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(child: FilledButton(onPressed: () => UrlHelper.launchURL(context, job.url), child: const Text('Apply'))),
              ],
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Row(
            children: [
              InitialAvatar(name: job.company, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.company, style: theme.textTheme.titleMedium),
                    Text(
                      [job.location, job.employmentType].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(job.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (job.salary != null) Tag(job.salary!, color: AppTheme.success, icon: Icons.payments_outlined),
              Tag(DateFormatter.timeAgo(job.postedDate ?? job.discoveredAt), icon: Icons.schedule_rounded),
              if (job.source != null) Tag(job.source!, icon: Icons.hub_outlined),
            ],
          ),
          const SizedBox(height: 20),
          AppCard(
            child: match.hasSufficientData
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${match.matchPercentage}%', style: theme.textTheme.headlineMedium?.copyWith(color: scoreColor(match.matchPercentage))),
                          const SizedBox(width: 8),
                          Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(match.label, style: theme.textTheme.titleSmall)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (final f in match.matchingFactors) _FactorLine(text: f, positive: true),
                      for (final g in match.gapFactors) _FactorLine(text: g, positive: false),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.info_outline_rounded),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Add skills to your profile or upload a resume to see how well you match.', style: theme.textTheme.bodySmall)),
                    ],
                  ),
          ),
          const SectionHeader(title: 'AI actions', padding: EdgeInsets.fromLTRB(0, 20, 0, 6)),
          _JobAiActions(job: job),
          if (job.description != null && job.description!.trim().isNotEmpty) ...[
            const SectionHeader(title: 'About the role', padding: EdgeInsets.fromLTRB(0, 20, 0, 6)),
            _ExpandableText(text: job.description!),
          ],
        ],
      ),
    );
  }
}

class _FactorLine extends StatelessWidget {
  final String text;
  final bool positive;

  const _FactorLine({required this.text, required this.positive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(positive ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded, size: 18, color: positive ? AppTheme.success : AppTheme.warning),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final long = widget.text.length > 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _open || !long ? null : 10,
          overflow: _open || !long ? null : TextOverflow.fade,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        if (long) TextButton(onPressed: () => setState(() => _open = !_open), child: Text(_open ? 'Show less' : 'Read more')),
      ],
    );
  }
}

class _JobAiActions extends ConsumerStatefulWidget {
  final Job job;
  const _JobAiActions({required this.job});

  @override
  ConsumerState<_JobAiActions> createState() => _JobAiActionsState();
}

class _JobAiActionsState extends ConsumerState<_JobAiActions> {
  String? _busy;
  String? _summary;

  String get _jobContext {
    final j = widget.job;
    final desc = j.description ?? '';
    return 'Job: ${j.title} at ${j.company} (${j.location ?? 'location n/a'})\nSkills: ${j.skills ?? '-'}\nDescription:\n'
        '${desc.length > 6000 ? desc.substring(0, 6000) : desc}';
  }

  String get _candidateContext {
    final p = ref.read(careerProfileProvider).valueOrNull;
    final resume = ref.read(primaryResumeProvider);
    final parsed = resume == null ? null : ref.read(parsedResumeProfilesProvider)[resume.id];
    return [
      'Candidate: ${p?.name ?? '[name]'}, ${p?.currentRole ?? ''}, ${p?.experienceYears ?? 0} years',
      'Skills: ${p?.skills ?? ''}',
      if (parsed?.rawText != null) 'Resume:\n${parsed!.rawText!.length > 6000 ? parsed.rawText!.substring(0, 6000) : parsed.rawText}',
    ].join('\n');
  }

  Future<void> _run(String key, Future<void> Function() task) async {
    setState(() => _busy = key);
    try {
      await task();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _quickFit() => _run('fit', () async {
        final text = await ref.read(aiServiceProvider).quick(
              'In at most 5 short bullet points ("- "): what this role really wants, where the candidate fits, and the biggest gap to address.\n\n$_jobContext\n\n$_candidateContext',
              system: 'You are a concise career coach. Be specific and honest. Output only the bullets.',
            );
        setState(() => _summary = text);
      });

  Future<void> _doc(String key, String title, String prompt) => _run(key, () async {
        final doc = await ref.read(documentServiceProvider).create(title: title, prompt: prompt);
        await DocumentService.open(doc.path);
      });

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    Widget action(String key, IconData icon, String title, String subtitle, VoidCallback onTap) => AppCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onTap: _busy == null ? onTap : null,
          child: Row(
            children: [
              Icon(icon, color: AppTheme.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              _busy == key
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right_rounded),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        action('fit', Icons.bolt_rounded, 'Quick fit check', 'What they want vs. what you have', _quickFit),
        if (_summary != null)
          AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            color: AppTheme.accent.withValues(alpha: 0.08),
            child: Text(_summary!, style: Theme.of(context).textTheme.bodyMedium),
          ),
        action(
          'cover',
          Icons.mail_outline_rounded,
          'Cover letter (PDF)',
          'Tailored to this role by Gemini',
          () => _doc(
            'cover',
            'Cover letter – ${j.company}',
            'Write a one-page cover letter for this job. # heading with the candidate name, then the letter. '
                'Mention 2-3 concrete achievements from the resume that match the role. Under 350 words.\n\n$_jobContext\n\n$_candidateContext',
          ),
        ),
        action(
          'research',
          Icons.travel_explore_rounded,
          'Company research brief (PDF)',
          'Interview prep: product, stack, likely questions',
          () => _doc(
            'research',
            'Research – ${j.company}',
            'Write an interview-prep brief for ${j.company} and this role: ## Company overview, ## Product & business model, '
                '## Likely tech stack & team, ## 10 likely interview questions with angles to answer, ## Questions to ask them. '
                'Only state facts you are confident about; mark uncertain points as "(verify)".\n\n$_jobContext',
          ),
        ),
      ],
    );
  }
}
