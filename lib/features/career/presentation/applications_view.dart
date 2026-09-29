import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../providers/career_providers.dart';
import 'add_edit_application_dialog.dart';

enum AppFilter { all, active, interviews, offers, followUp, closed }

const _activeStatuses = {'saved', 'applying', 'applied', 'screening'};
const _interviewStatuses = {'interview', 'technical', 'hr'};
const _closedStatuses = {'rejected', 'withdrawn'};

bool _followUpDue(JobApplication a, DateTime now) {
  if (a.followUpDate == null || _closedStatuses.contains(a.status.toLowerCase())) return false;
  final d = a.followUpDate!;
  return !DateTime(d.year, d.month, d.day).isAfter(DateTime(now.year, now.month, now.day));
}

/// Pure filter for the Applied tab (tested directly).
List<JobApplication> filterApplications(List<JobApplication> apps, AppFilter filter, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final list = apps.where((a) {
    final s = a.status.toLowerCase();
    return switch (filter) {
      AppFilter.all => true,
      AppFilter.active => _activeStatuses.contains(s),
      AppFilter.interviews => _interviewStatuses.contains(s),
      AppFilter.offers => s == 'offer',
      AppFilter.followUp => _followUpDue(a, today),
      AppFilter.closed => _closedStatuses.contains(s),
    };
  }).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return list;
}

Color applicationStatusColor(String status) => switch (status.toLowerCase()) {
      'offer' => AppTheme.success,
      'interview' || 'technical' || 'hr' => AppTheme.info,
      'rejected' || 'withdrawn' => AppTheme.error,
      'screening' => AppTheme.violet,
      _ => AppTheme.textMid,
    };

final appFilterProvider = StateProvider<AppFilter>((ref) => AppFilter.all);

class ApplicationsView extends ConsumerWidget {
  const ApplicationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(allApplicationsProvider).valueOrNull ?? const <JobApplication>[];
    final filter = ref.watch(appFilterProvider);
    final visible = filterApplications(apps, filter);
    final counts = {for (final f in AppFilter.values) f: filterApplications(apps, f).length};
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'log-application',
        onPressed: () => showDialog(context: context, builder: (_) => const AddEditApplicationDialog()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log application'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FilterPills<AppFilter>(
              options: const [
                (AppFilter.all, 'All'),
                (AppFilter.active, 'Active'),
                (AppFilter.interviews, 'Interviews'),
                (AppFilter.offers, 'Offers'),
                (AppFilter.followUp, 'Follow-up due'),
                (AppFilter.closed, 'Closed'),
              ],
              counts: counts,
              selected: filter,
              onSelected: (f) => ref.read(appFilterProvider.notifier).state = f,
            ),
          ),
          if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: apps.isEmpty
                  ? const EmptyHint(
                      icon: Icons.assignment_outlined,
                      title: 'No applications yet',
                      message: 'Open a job and tap “Mark as applied”, or log one with the button below.',
                    )
                  : const EmptyHint(icon: Icons.filter_alt_off_rounded, title: 'Nothing here', message: 'No applications in this filter.'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final a = visible[i];
                  final status = ApplicationStatus.fromString(a.status);
                  final due = _followUpDue(a, DateTime.now());
                  return AppCard(
                    onTap: () => context.push('/career/application/${a.id}'),
                    child: Row(
                      children: [
                        InitialAvatar(name: a.company),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.role, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                [a.company, if (a.appliedAt != null) 'Applied ${DateFormatter.formatShortDate(a.appliedAt)}'].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                              if (due)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Tag('Follow up ${DateFormatter.formatRelative(a.followUpDate)}', color: AppTheme.warning, icon: Icons.alarm_rounded),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tag(status.label, color: applicationStatusColor(a.status)),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
