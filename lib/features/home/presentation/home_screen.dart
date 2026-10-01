import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_keys.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../career/presentation/applications_view.dart';
import '../../career/presentation/live_jobs_view.dart';
import '../../career/providers/career_providers.dart';
import '../../freelance/business/business_discovery_service.dart';
import '../../freelance/presentation/freelance_screen.dart';
import '../../freelance/providers/freelance_providers.dart';
import '../../track/providers/track_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static String _greeting(DateTime now) => now.hour < 12
      ? 'Good morning'
      : now.hour < 17
          ? 'Good afternoon'
          : 'Good evening';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dayAgo = now.subtract(const Duration(hours: 24));
    final profile = ref.watch(careerProfileProvider).valueOrNull;
    final jobs = ref.watch(allJobsProvider).valueOrNull ?? const <Job>[];
    final leads = ref.watch(businessLeadsProvider).valueOrNull ?? const <BusinessLead>[];
    final apps = ref.watch(allApplicationsProvider).valueOrNull ?? const <JobApplication>[];
    final problems = ref.watch(dsaProblemsStreamProvider).valueOrNull ?? const <DSAProblem>[];
    final habits = ref.watch(habitsProvider).valueOrNull ?? const <Habit>[];
    final done = ref.watch(habitDoneDaysProvider);
    final reflections = ref.watch(reflectionsProvider).valueOrNull ?? const <DailyReflection>[];
    final keys = ref.watch(aiKeysProvider);

    final bestMatches = filterJobs(jobs, profile, filter: JobFilter.bestMatch);
    final newJobs = jobs.where((j) => j.discoveredAt.isAfter(dayAgo)).length;
    final newLeads = leads.where((l) => l.discoveredAt.isAfter(dayAgo)).length;
    final freshLeads = leads.where((l) => l.status == 'NEW').toList();
    final activeApps = filterApplications(apps, AppFilter.active).length + filterApplications(apps, AppFilter.interviews).length;
    final solved = problems.where((p) => p.status == 'SOLVED').length;
    final today = dayKey(now);
    final habitsDone = habits.where((h) => done[h.id]?.contains(today) ?? false).length;
    final reflected = reflections.any((r) => dayKey(r.day) == today);
    final firstName = (profile?.name ?? '').split(' ').first;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(now), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        Text(firstName.isEmpty ? 'Welcome' : firstName, style: theme.textTheme.headlineSmall),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: () => context.push('/settings'),
                    icon: InitialAvatar(name: profile?.name ?? 'Me', size: 36),
                  ),
                ],
              ),
            ),
            if (!keys.has(AiProvider.gemini))
              AppCard(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                color: AppTheme.warning.withValues(alpha: 0.1),
                onTap: () => context.push('/settings/ai'),
                child: Row(
                  children: [
                    const Icon(Icons.key_rounded, color: AppTheme.warning),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Optional: Connect Gemini in Settings to generate cover letters and proposals.', style: theme.textTheme.bodySmall)),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            AppCard(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New opportunities today', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${newJobs + newLeads}', style: theme.textTheme.displaySmall),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('$newJobs jobs · $newLeads leads', style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.success)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: StatTile(value: '${bestMatches.length}', label: 'Best-match jobs', valueColor: AppTheme.success, onTap: () => context.go('/career'))),
                      const SizedBox(width: 10),
                      Expanded(child: StatTile(value: '$activeApps', label: 'Active applications', onTap: () => context.go('/career'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: StatTile(value: '${freshLeads.length}', label: '₹1Cr+ leads to contact', onTap: () => context.go('/freelance'))),
                      const SizedBox(width: 10),
                      Expanded(child: StatTile(value: '$solved/${problems.length}', label: 'LeetCode solved', onTap: () => context.go('/track'))),
                    ],
                  ),
                ],
              ),
            ),
            SectionHeader(title: 'Top job matches', actionLabel: 'See all', onAction: () => context.go('/career')),
            if (bestMatches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  profile?.skills == null ? 'Add skills or a resume to get matches.' : 'No strong matches yet. Refresh jobs in Career.',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              for (final (job, match) in bestMatches.take(3))
                Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: JobCard(job: job, match: match)),
            SectionHeader(title: 'Businesses that need a website', actionLabel: 'See all', onAction: () => context.go('/freelance')),
            if (freshLeads.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Find ₹1 Cr+ businesses without a proper site in Freelance.', style: theme.textTheme.bodySmall),
              )
            else
              for (final lead in (freshLeads..sort((a, b) => b.needScore.compareTo(a.needScore))).take(3))
                Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: BusinessLeadCard(lead: lead)),
            const SectionHeader(title: 'Today'),
            AppCard(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _TodayRow(
                    icon: Icons.repeat_rounded,
                    title: habits.isEmpty ? 'Set up daily habits' : 'Habits',
                    trailing: habits.isEmpty ? null : '$habitsDone/${habits.length}',
                    done: habits.isNotEmpty && habitsDone == habits.length,
                    onTap: () => context.go('/track'),
                  ),
                  const Divider(indent: 56),
                  _TodayRow(
                    icon: Icons.edit_note_rounded,
                    title: reflected ? 'Reflection written' : 'Write today’s reflection',
                    done: reflected,
                    onTap: () => context.go('/track'),
                  ),
                  if (freshLeads.isNotEmpty) ...[
                    const Divider(indent: 56),
                    _TodayRow(
                      icon: Icons.storefront_outlined,
                      title: 'Contact ${freshLeads.first.name}',
                      trailing: formatInr(freshLeads.first.turnoverInr),
                      onTap: () => context.push('/freelance/business/${freshLeads.first.id}'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final bool done;
  final VoidCallback onTap;

  const _TodayRow({required this.icon, required this.title, this.trailing, this.done = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(done ? Icons.check_circle_rounded : icon, color: done ? AppTheme.success : theme.colorScheme.onSurfaceVariant),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      trailing: trailing == null ? const Icon(Icons.chevron_right_rounded) : Text(trailing!, style: theme.textTheme.titleSmall),
    );
  }
}
