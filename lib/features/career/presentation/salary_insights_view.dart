import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/salary_parser.dart';
import '../providers/career_providers.dart';
import 'job_details_screen.dart';

/// Salary benchmarks computed from the pay ranges published on discovered
/// and saved jobs (RemoteOK, Lever and manually added postings).
class SalaryInsightsView extends ConsumerStatefulWidget {
  const SalaryInsightsView({super.key});

  @override
  ConsumerState<SalaryInsightsView> createState() => _SalaryInsightsViewState();
}

class _SalaryInsightsViewState extends ConsumerState<SalaryInsightsView> {
  bool _myRoleOnly = false;

  static double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0;
    final idx = (sorted.length - 1) * p;
    final lo = idx.floor();
    final hi = idx.ceil();
    return sorted[lo] + (sorted[hi] - sorted[lo]) * (idx - lo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobs = ref.watch(allJobsProvider).valueOrNull ?? const <Job>[];
    final profile = ref.watch(careerProfileProvider).valueOrNull;
    final roleWords = '${profile?.currentRole ?? ''} ${profile?.preferredRoles ?? ''}'
        .toLowerCase()
        .split(RegExp(r'[^a-z+#]+'))
        .where((w) => w.length > 3 && !{'senior', 'junior', 'lead', 'staff', 'principal'}.contains(w))
        .toSet();

    final withPay = <(Job, SalaryRange)>[];
    var otherCurrency = 0;
    for (final j in jobs) {
      final range = SalaryParser.parse(j.salary);
      if (range == null) continue;
      if (range.currency != 'USD') {
        otherCurrency++;
        continue;
      }
      if (_myRoleOnly && roleWords.isNotEmpty && !roleWords.any(j.title.toLowerCase().contains)) continue;
      withPay.add((j, range));
    }

    if (withPay.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (roleWords.isNotEmpty) _roleToggle(),
          const SizedBox(height: 48),
          Icon(Icons.payments_outlined, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text('No salary data yet',
              textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Insights appear once discovered jobs publish pay ranges (RemoteOK and Lever often do). Run Discover on the Radar tab.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }

    final mids = withPay.map((e) => e.$2.mid).toList()..sort();
    final p25 = _percentile(mids, 0.25);
    final p50 = _percentile(mids, 0.5);
    final p75 = _percentile(mids, 0.75);
    const buckets = [(0.0, 80000.0), (80000.0, 120000.0), (120000.0, 160000.0), (160000.0, 200000.0), (200000.0, 250000.0), (250000.0, double.infinity)];
    final counts = [for (final b in buckets) mids.where((m) => m >= b.$1 && m < b.$2).length];
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    final top = [...withPay]..sort((a, b) => b.$2.max.compareTo(a.$2.max));
    String fmt(double v) => SalaryParser.format(v);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        if (roleWords.isNotEmpty) _roleToggle(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Median annual pay (USD)', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(fmt(p50), style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.success)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _Stat(label: '25th pct', value: fmt(p25))),
                    Expanded(child: _Stat(label: '75th pct', value: fmt(p75))),
                    Expanded(child: _Stat(label: 'Postings', value: '${withPay.length}')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'From ${withPay.length} of ${jobs.length} jobs that list pay. Hourly rates annualized at 2,080 h.'
                  '${otherCurrency > 0 ? ' $otherCurrency non-USD postings excluded.' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Distribution', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                for (var i = 0; i < buckets.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 92,
                          child: Text(
                            buckets[i].$2.isInfinite ? '${fmt(buckets[i].$1)}+' : '${fmt(buckets[i].$1)}–${fmt(buckets[i].$2)}',
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: maxCount == 0 ? 0 : counts[i] / maxCount,
                              minHeight: 12,
                              color: theme.colorScheme.primary,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        SizedBox(width: 32, child: Text('${counts[i]}', textAlign: TextAlign.end, style: theme.textTheme.labelMedium)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Highest paying', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final (job, range) in top.take(10))
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(job.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(job.company, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(
                range.min == range.max ? fmt(range.max) : '${fmt(range.min)}–${fmt(range.max)}',
                style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.success, fontWeight: FontWeight.w700),
              ),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsScreen(jobId: job.id))),
            ),
          ),
      ],
    );
  }

  Widget _roleToggle() => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 8,
          children: [
            ChoiceChip(label: const Text('All roles'), selected: !_myRoleOnly, onSelected: (_) => setState(() => _myRoleOnly = false)),
            ChoiceChip(label: const Text('My target role'), selected: _myRoleOnly, onSelected: (_) => setState(() => _myRoleOnly = true)),
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
