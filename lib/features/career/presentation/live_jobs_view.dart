import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_keys.dart';
import '../../../core/ai/ai_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/feed_widgets.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../domain/job_match_service.dart';
import '../providers/career_providers.dart';
import '../services/ai_job_search_service.dart';

enum JobFilter { all, bestMatch, remote, fresh, saved }

/// Pure filter used by the Jobs tab (and tests): returns jobs with their
/// match, sorted by match then recency.
List<(Job, JobMatchResult)> filterJobs(
  List<Job> jobs,
  UserProfile? profile, {
  JobFilter filter = JobFilter.all,
  String query = '',
  DateTime? now,
}) {
  final q = query.trim().toLowerCase();
  final cutoff = (now ?? DateTime.now()).subtract(const Duration(days: 3));
  final out = <(Job, JobMatchResult)>[];
  for (final j in jobs) {
    if (q.isNotEmpty && !'${j.title} ${j.company} ${j.skills ?? ''} ${j.location ?? ''}'.toLowerCase().contains(q)) continue;
    final match = j.matchScore != null
        ? JobMatchResult.fromStoredScore(j.matchScore!)
        : JobMatchService.calculateMatch(job: j, profile: profile);
    final keep = switch (filter) {
      JobFilter.all => true,
      JobFilter.bestMatch => match.hasSufficientData && match.matchPercentage >= 70,
      JobFilter.remote => '${j.location ?? ''} ${j.employmentType ?? ''}'.toLowerCase().contains('remote'),
      JobFilter.fresh => (j.postedDate ?? j.discoveredAt).isAfter(cutoff),
      JobFilter.saved => j.isSaved,
    };
    if (keep) out.add((j, match));
  }
  out.sort((a, b) {
    final byScore = b.$2.matchPercentage.compareTo(a.$2.matchPercentage);
    return byScore != 0 ? byScore : (b.$1.postedDate ?? b.$1.discoveredAt).compareTo(a.$1.postedDate ?? a.$1.discoveredAt);
  });
  return out;
}

final jobFilterSelectionProvider = StateProvider<JobFilter>((ref) => JobFilter.all);
final jobQueryProvider = StateProvider<String>((ref) => '');

class LiveJobsView extends ConsumerStatefulWidget {
  const LiveJobsView({super.key});

  @override
  ConsumerState<LiveJobsView> createState() => _LiveJobsViewState();
}

class _LiveJobsViewState extends ConsumerState<LiveJobsView> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-sync public boards when there are no live jobs or the last sync is > 6h old.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(liveDiscoveryProvider.notifier);
      final jobs = await ref.read(allJobsProvider.future);
      if (!mounted) return;
      if (!jobs.any((j) => j.atsProvider != null) || notifier.isStale()) _refresh(showSnack: false);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool showSnack = true}) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(liveDiscoveryProvider.notifier).discoverJobs();
    if (mounted && showSnack && result != null) messenger.showSnackBar(SnackBar(content: Text(result.summary)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobs = ref.watch(allJobsProvider).valueOrNull;
    final profile = ref.watch(careerProfileProvider).valueOrNull;
    final discovery = ref.watch(liveDiscoveryProvider);
    final filter = ref.watch(jobFilterSelectionProvider);
    final query = ref.watch(jobQueryProvider);

    final all = jobs ?? const <Job>[];
    final counts = {for (final f in JobFilter.values) f: filterJobs(all, profile, filter: f, query: query).length};
    final visible = filterJobs(all, profile, filter: filter, query: query);
    final failed = discovery.lastResult?.failedSources ?? const [];

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SearchField(
                      controller: _search,
                      hint: 'Search title, company, skill',
                      onChanged: (v) {
                        ref.read(jobQueryProvider.notifier).state = v;
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Search with AI',
                    onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const AiJobSearchSheet()),
                    icon: const Icon(Icons.auto_awesome_rounded),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FilterPills<JobFilter>(
              options: const [
                (JobFilter.all, 'All'),
                (JobFilter.bestMatch, 'Best match'),
                (JobFilter.remote, 'Remote'),
                (JobFilter.fresh, 'New'),
                (JobFilter.saved, 'Saved'),
              ],
              counts: counts,
              selected: filter,
              onSelected: (f) => ref.read(jobFilterSelectionProvider.notifier).state = f,
            ),
          ),
          if (discovery.isLoading) const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2)),
          if (!discovery.isLoading && (discovery.error != null || (discovery.lastResult?.allSourcesFailed ?? false)))
            SliverToBoxAdapter(
              child: StatusBanner(
                tone: BannerTone.error,
                title: 'Couldn’t reach the job boards',
                message: discovery.error ?? failed.first.error,
                onRetry: _refresh,
              ),
            )
          else if (!discovery.isLoading && failed.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () => showSourceStatusSheet(context, discovery.lastResult!.sources),
                  child: Text(
                    '${failed.length} of ${discovery.lastResult!.sources.length} sources didn’t respond · details',
                    style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.warning),
                  ),
                ),
              ),
            ),
          if (jobs == null)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.builder(itemCount: 4, itemBuilder: (_, __) => const SkeletonCard()),
            )
          else if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: all.isEmpty
                  ? EmptyHint(
                      icon: Icons.radar_rounded,
                      title: discovery.isLoading ? 'Fetching live jobs…' : 'No jobs yet',
                      message: 'Pull down to fetch from Greenhouse, Lever, Ashby, RemoteOK and WeWorkRemotely, or tap ✦ to search with AI.',
                    )
                  : EmptyHint(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'No jobs in this filter',
                      message: filter == JobFilter.bestMatch && profile?.skills == null
                          ? 'Add skills to your profile (or upload a resume) to get match scores.'
                          : 'Try another filter or search term.',
                    ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => JobCard(job: visible[i].$1, match: visible[i].$2),
              ),
            ),
        ],
      ),
    );
  }
}

class JobCard extends ConsumerWidget {
  final Job job;
  final JobMatchResult match;

  const JobCard({super.key, required this.job, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final posted = DateFormatter.timeAgo(job.postedDate ?? job.discoveredAt);
    return AppCard(
      onTap: () => context.push('/career/job/${job.id}'),
      padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialAvatar(name: job.company),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.25)),
                const SizedBox(height: 3),
                Text(
                  [job.company, if (job.location != null && job.location!.isNotEmpty) job.location].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (job.salary != null) ...[
                      Flexible(
                        child: Text(job.salary!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.success, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(posted, style: theme.textTheme.labelSmall),
                    if (job.source != null) ...[
                      Text('  ·  ', style: theme.textTheme.labelSmall),
                      Flexible(child: Text(job.source!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (match.hasSufficientData)
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 10),
                  child: Text('${match.matchPercentage}%', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: scoreColor(match.matchPercentage))),
                ),
              IconButton(
                tooltip: job.isSaved ? 'Unsave' : 'Save',
                onPressed: () => ref.read(databaseProvider).toggleJobSaved(job.id, !job.isSaved),
                icon: Icon(job.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: job.isSaved ? AppTheme.accent : null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AiJobSearchSheet extends ConsumerStatefulWidget {
  const AiJobSearchSheet({super.key});

  @override
  ConsumerState<AiJobSearchSheet> createState() => _AiJobSearchSheetState();
}

class _AiJobSearchSheetState extends ConsumerState<AiJobSearchSheet> {
  late final TextEditingController _query;
  late final TextEditingController _location;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = ref.read(careerProfileProvider).valueOrNull;
    _query = TextEditingController(text: (p?.preferredRoles ?? p?.currentRole ?? '').split(',').first.trim());
    _location = TextEditingController(text: (p?.preferredLocations ?? 'India').split(',').first.trim());
  }

  @override
  void dispose() {
    _query.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_query.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final profile = ref.read(careerProfileProvider).valueOrNull;
      final result = await AiJobSearchService(db: ref.read(databaseProvider), claude: ref.read(aiServiceProvider).claude).search(
        query: _query.text.trim(),
        location: _location.text.trim(),
        skills: (profile?.skills ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      );
      ref.read(jobFilterSelectionProvider.notifier).state = JobFilter.all;
      if (mounted) Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(result.summary)));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasClaude = ref.watch(aiKeysProvider).has(AiProvider.claude);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Search with AI', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Claude searches LinkedIn, Naukri, Instahyre, Wellfound and company career pages live.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(controller: _query, decoration: const InputDecoration(hintText: 'Role, e.g. Flutter developer', prefixIcon: Icon(Icons.work_outline_rounded))),
          const SizedBox(height: 10),
          TextField(controller: _location, decoration: const InputDecoration(hintText: 'Location, e.g. Bengaluru or Remote', prefixIcon: Icon(Icons.place_outlined))),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.error)),
            const SizedBox(height: 10),
          ],
          if (!hasClaude)
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/settings/ai');
              },
              child: const Text('Add Claude key first'),
            )
          else if (_busy) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text('Searching… this can take a minute.', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ] else
            FilledButton.icon(onPressed: _run, icon: const Icon(Icons.auto_awesome_rounded, size: 18), label: const Text('Find jobs')),
        ],
      ),
    );
  }
}
