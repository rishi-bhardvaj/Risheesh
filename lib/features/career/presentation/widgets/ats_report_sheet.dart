import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/resume_profile_models.dart';
import '../../providers/career_providers.dart';
import '../../services/ats_scoring_service.dart';

Color atsColor(int score) => score >= 70
    ? AppTheme.success
    : score >= 50
        ? AppTheme.warning
        : AppTheme.error;

/// Circular ATS score badge used on resume cards and in the sheet.
class AtsScoreRing extends StatelessWidget {
  final int score;
  final double size;

  const AtsScoreRing({super.key, required this.score, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final color = atsColor(score);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: size / 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
          Text(
            '$score',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: size * 0.32, color: color),
          ),
        ],
      ),
    );
  }
}

Future<void> showAtsReportSheet(BuildContext context, Resume resume) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => AtsReportSheet(resume: resume),
    );

class AtsReportSheet extends ConsumerStatefulWidget {
  final Resume resume;

  const AtsReportSheet({super.key, required this.resume});

  @override
  ConsumerState<AtsReportSheet> createState() => _AtsReportSheetState();
}

class _AtsReportSheetState extends ConsumerState<AtsReportSheet> {
  String? _jobId;
  bool _applying = false;

  Future<void> _applyToProfile(ResumeProfile profile) async {
    setState(() => _applying = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(resumeIngestServiceProvider).applyToProfile(profile);
      messenger.showSnackBar(SnackBar(
        content: Text(result.fieldsFilled.isEmpty && result.skillsAdded == 0
            ? 'Your profile already has everything from this resume.'
            : 'Updated ${result.fieldsFilled.join(', ')}${result.skillsAdded > 0 ? ' · ${result.skillsAdded} skills added to tracker' : ''}'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not update profile: $e')));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(parsedResumeProfilesProvider)[widget.resume.id];
    final report = ref.watch(atsReportProvider((resumeId: widget.resume.id, jobId: _jobId)));
    final jobs = [...(ref.watch(allJobsProvider).valueOrNull ?? const <Job>[])]
      ..sort((a, b) => (b.isSaved ? 1 : 0).compareTo(a.isSaved ? 1 : 0));

    if (profile == null || report == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('This resume hasn’t been parsed yet. Tap “Parse” on its card first.'),
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Row(
            children: [
              AtsScoreRing(score: report.total, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ATS score · ${report.grade}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      report.scoredAgainstJob ? 'Scored against the selected job' : 'General readiness. Pick a job for keyword gaps.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            value: _jobId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Score against job', prefixIcon: Icon(Icons.work_outline_rounded)),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('No specific job (general score)')),
              for (final j in jobs.take(150))
                DropdownMenuItem<String?>(
                  value: j.id,
                  child: Text('${j.isSaved ? '★ ' : ''}${j.title} · ${j.company}', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _jobId = v),
          ),
          const SizedBox(height: 20),
          for (final f in report.factors) _FactorBar(factor: f),
          if (report.scoredAgainstJob) ...[
            const SizedBox(height: 8),
            _KeywordWrap(title: 'Matched keywords', words: report.matchedKeywords, color: AppTheme.success),
            _KeywordWrap(title: 'Missing keywords', words: report.missingKeywords.take(15).toList(), color: AppTheme.error),
          ],
          if (report.suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('How to improve', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final s in report.suggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates_outlined, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 16),
          _ExtractedSummary(profile: profile),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _applying ? null : () => _applyToProfile(profile),
            icon: _applying
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.person_add_alt_rounded),
            label: const Text('Apply to my profile & skills'),
          ),
        ],
      ),
    );
  }
}

class _FactorBar extends StatelessWidget {
  final AtsFactor factor;

  const _FactorBar({required this.factor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = atsColor((factor.ratio * 100).round());
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(factor.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
              Text('${factor.score}/${factor.maxScore}', style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: factor.ratio, minHeight: 6, color: color, backgroundColor: color.withValues(alpha: 0.15)),
          ),
          for (final n in factor.notes)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(n, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}

class _KeywordWrap extends StatelessWidget {
  final String title;
  final List<String> words;
  final Color color;

  const _KeywordWrap({required this.title, required this.words, required this.color});

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final w in words)
                Chip(
                  label: Text(w),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                  backgroundColor: color.withValues(alpha: 0.08),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExtractedSummary extends StatelessWidget {
  final ResumeProfile profile;

  const _ExtractedSummary({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(IconData icon, String label, String? value) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                SizedBox(width: 84, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
              ],
            ),
          );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Extracted from resume', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            row(Icons.person_outline, 'Name', profile.fullName?.value),
            row(Icons.badge_outlined, 'Headline', profile.targetRole?.value),
            row(Icons.mail_outline, 'Email', profile.email?.value),
            row(Icons.phone_outlined, 'Phone', profile.phone?.value),
            row(Icons.link, 'LinkedIn', profile.linkedin?.value),
            row(Icons.code, 'GitHub', profile.github?.value),
            row(Icons.timeline, 'Experience', profile.experienceYears == null ? null : '${profile.experienceYears!.value} years'),
            row(Icons.school_outlined, 'Education', profile.educationEntries.join('\n')),
            row(Icons.build_outlined, 'Skills', profile.allUniqueSkills.join(', ')),
            if (profile.experience.isNotEmpty) ...[
              const Divider(height: 20),
              for (final e in profile.experience)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text([e.role, if (e.company != null) e.company].join(' · '), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      if (e.dateRange != null)
                        Text(e.dateRange!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      Text('${e.bullets.length} bullet points', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
