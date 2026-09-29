import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/url_helper.dart';
import '../../../shared/widgets/feed_widgets.dart';
import '../providers/track_providers.dart';
import 'add_edit_dsa_dialog.dart';
import 'dsa_problem_details_screen.dart';

Color difficultyColor(String difficulty) => switch (difficulty.toUpperCase()) {
      'EASY' => AppTheme.success,
      'HARD' => AppTheme.error,
      _ => AppTheme.warning,
    };

/// LeetCode / DSA tracker: 500-problem sync, search, topic chips with
/// counts, difficulty filter, and one-tap solved checkboxes.
class DsaTab extends ConsumerStatefulWidget {
  const DsaTab({super.key});

  @override
  ConsumerState<DsaTab> createState() => _DsaTabState();
}

class _DsaTabState extends ConsumerState<DsaTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(dsaSyncProvider.notifier).sync(limit: 500);
    if (!mounted || result == null) return;
    messenger.showSnackBar(SnackBar(content: Text(result.summary), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = ref.watch(dsaProblemsStreamProvider).valueOrNull ?? const <DSAProblem>[];
    final problems = ref.watch(filteredDSAProblemsProvider);
    final topics = ref.watch(dsaTopicCountsProvider);
    final topic = ref.watch(dsaTopicFilterProvider);
    final difficulty = ref.watch(dsaDifficultyFilterProvider);
    final sync = ref.watch(dsaSyncProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'dsa-add',
        tooltip: 'Add problem manually',
        onPressed: () => showDialog(context: context, builder: (_) => const AddEditDSADialog()),
        child: const Icon(Icons.add_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: _sync,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _ProgressHeader(problems: all)),
            SliverToBoxAdapter(child: _buildSyncCard(theme, all.length, sync)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search problems, e.g. "two sum" or "#146"',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(dsaSearchQueryProvider.notifier).state = '';
                              setState(() {});
                            },
                          ),
                  ),
                  onChanged: (v) {
                    // "#146" searches by LeetCode number, which titles start with.
                    ref.read(dsaSearchQueryProvider.notifier).state = v.startsWith('#') ? '${v.substring(1)}.' : v;
                    setState(() {});
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text('All ${all.length}'),
                        selected: topic == 'all',
                        onSelected: (_) => ref.read(dsaTopicFilterProvider.notifier).state = 'all',
                      ),
                    ),
                    for (final e in topics.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text('${e.key} ${e.value}'),
                          selected: topic.toLowerCase() == e.key.toLowerCase(),
                          onSelected: (sel) => ref.read(dsaTopicFilterProvider.notifier).state = sel ? e.key : 'all',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children: [
                          for (final d in const ['all', 'EASY', 'MEDIUM', 'HARD'])
                            ChoiceChip(
                              label: Text(d == 'all' ? 'Any' : d[0] + d.substring(1).toLowerCase()),
                              selected: difficulty == d,
                              selectedColor: d == 'all' ? null : difficultyColor(d).withValues(alpha: 0.2),
                              onSelected: (_) => ref.read(dsaDifficultyFilterProvider.notifier).state = d,
                            ),
                        ],
                      ),
                    ),
                    _StatusMenu(),
                    _SortMenu(),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '${problems.length} of ${all.length} problems',
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            if (problems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      all.isEmpty ? 'No problems yet. Sync the LeetCode bank above to get started.' : 'No problems match these filters.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                sliver: SliverList.builder(
                  itemCount: problems.length,
                  itemBuilder: (context, i) => DsaProblemTile(problem: problems[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncCard(ThemeData theme, int total, DsaSyncState sync) {
    final result = sync.lastResult;
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Icon(Icons.cloud_sync_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LeetCode problem bank', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        total == 0
                            ? 'Pull 500 problems (5 parallel pages of 100) with difficulty, tags and acceptance.'
                            : '$total problems tracked · pull to refresh',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: sync.isLoading ? null : _sync,
                  child: sync.isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(total == 0 ? 'Sync 500' : 'Sync'),
                ),
              ],
            ),
          ),
        ),
        if (sync.error != null)
          StatusBanner(tone: BannerTone.error, title: 'Sync failed', message: sync.error, onRetry: _sync)
        else if (result != null && !result.fetch.fromNetwork)
          StatusBanner(
            tone: BannerTone.warning,
            title: 'LeetCode unreachable, loaded the offline bank',
            message: '${result.fetch.problems.length} curated problems. ${result.fetch.error ?? ''}'.trim(),
            onRetry: _sync,
          )
        else if (result != null && result.fetch.pagesFailed > 0)
          StatusBanner(
            tone: BannerTone.warning,
            title: '${result.fetch.pagesFailed} of ${result.fetch.pagesRequested} pages failed',
            message: 'Synced what came back; retry to fill the gaps.',
            onRetry: _sync,
          ),
      ],
    );
  }
}

class _StatusMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(dsaStatusFilterProvider);
    return PopupMenuButton<String>(
      tooltip: 'Filter by status',
      initialValue: status,
      icon: Badge(isLabelVisible: status != 'all', child: const Icon(Icons.checklist_rounded)),
      onSelected: (v) => ref.read(dsaStatusFilterProvider.notifier).state = v,
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'all', child: Text('All statuses')),
        for (final s in DSAStatus.values) PopupMenuItem(value: s.value, child: Text(s.label)),
      ],
    );
  }
}

class _SortMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(dsaSortOptionProvider);
    return PopupMenuButton<DSASortOption>(
      tooltip: 'Sort',
      initialValue: sort,
      icon: const Icon(Icons.sort_rounded),
      onSelected: (v) => ref.read(dsaSortOptionProvider.notifier).state = v,
      itemBuilder: (_) => [for (final s in DSASortOption.values) PopupMenuItem(value: s, child: Text(s.label))],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final List<DSAProblem> problems;

  const _ProgressHeader({required this.problems});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final solved = problems.where((p) => p.status == 'SOLVED').toList();
    int count(List<DSAProblem> list, String d) => list.where((p) => p.difficulty == d).length;
    final ratio = problems.isEmpty ? 0.0 : solved.length / problems.length;

    Widget stat(String label, String d) {
      final color = difficultyColor(d);
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
            Text(
              '${count(solved, d)}/${count(problems, d)}',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${solved.length}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                Text(' / ${problems.length} solved', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const Spacer(),
                Text('${(ratio * 100).toStringAsFixed(0)}%', style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.success, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: ratio, minHeight: 6, color: AppTheme.success),
            ),
            const SizedBox(height: 12),
            Row(children: [stat('EASY', 'EASY'), stat('MEDIUM', 'MEDIUM'), stat('HARD', 'HARD')]),
          ],
        ),
      ),
    );
  }
}

class DsaProblemTile extends ConsumerWidget {
  final DSAProblem problem;

  const DsaProblemTile({super.key, required this.problem});

  static final _acceptance = RegExp(r'Acceptance: ([\d.]+)%');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final solved = problem.status == 'SOLVED';
    final acceptance = _acceptance.firstMatch(problem.notes ?? '')?.group(1);
    final premium = (problem.notes ?? '').contains('LeetCode Premium');
    final color = difficultyColor(problem.difficulty);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DSAProblemDetailsScreen(problem: problem))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Row(
            children: [
              Checkbox(
                value: solved,
                activeColor: AppTheme.success,
                onChanged: (v) => ref
                    .read(trackRepositoryProvider)
                    .updateDSAStatus(problem.id, v == true ? DSAStatus.solved : DSAStatus.todo),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      problem.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: solved ? TextDecoration.lineThrough : null,
                        color: solved ? theme.colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        MetaChip(label: problem.difficulty[0] + problem.difficulty.substring(1).toLowerCase(), color: color),
                        MetaChip(label: problem.topic),
                        if (acceptance != null) MetaChip(label: '$acceptance% AC'),
                        if (premium) const MetaChip(label: 'Premium', icon: Icons.lock_outline_rounded, color: AppTheme.warning),
                        if (problem.status == 'NEEDS_REVISION') const MetaChip(label: 'Revise', color: AppTheme.error),
                        if (problem.status == 'ATTEMPTED') const MetaChip(label: 'Attempted', color: AppTheme.warning),
                      ],
                    ),
                  ],
                ),
              ),
              if (problem.url != null)
                IconButton(
                  tooltip: 'Open on LeetCode',
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  onPressed: () => UrlHelper.launchURL(context, problem.url),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
