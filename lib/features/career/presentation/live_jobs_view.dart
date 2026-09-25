import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/app_database.dart';
import '../domain/job_match_service.dart';
import '../providers/career_providers.dart';
import 'job_details_screen.dart';
import 'widgets/job_ai_analysis_dialog.dart';
import 'widgets/resume_selector_banner.dart';

class LiveJobsView extends ConsumerStatefulWidget {
  const LiveJobsView({super.key});

  @override
  ConsumerState<LiveJobsView> createState() => _LiveJobsViewState();
}

class _LiveJobsViewState extends ConsumerState<LiveJobsView> {
  String _searchFilter = '';
  String _selectedFilter = 'ALL'; // ALL, STRONG_MATCH, REMOTE, SAVED

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobsAsync = ref.watch(allJobsProvider);
    final profileAsync = ref.watch(careerProfileProvider);
    final discoveryState = ref.watch(liveDiscoveryProvider);

    return Scaffold(
      body: Column(
        children: [
          const ResumeSelectorBanner(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search discovered jobs...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      suffixIcon: _searchFilter.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _searchFilter = ''),
                            )
                          : null,
                    ),
                    onChanged: (val) => setState(() => _searchFilter = val),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: discoveryState.isLoading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final result = await ref.read(liveDiscoveryProvider.notifier).discoverJobs();
                          if (mounted && result != null) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Discovered ${result.totalDiscovered} jobs: ${result.newJobsSaved} new saved, ${result.duplicatesSkipped} duplicates skipped.',
                                ),
                              ),
                            );
                          }
                        },
                  icon: discoveryState.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.radar, size: 18),
                  label: Text(discoveryState.isLoading ? 'Discovering...' : 'Discover Live'),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Jobs'),
                const SizedBox(width: 8),
                _buildFilterChip('STRONG_MATCH', '🎯 Strong Match (≥80%)'),
                const SizedBox(width: 8),
                _buildFilterChip('REMOTE', '🌐 Remote Only'),
                const SizedBox(width: 8),
                _buildFilterChip('SAVED', '⭐ Saved / Bookmarked'),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: jobsAsync.when(
              data: (jobs) {
                final profile = profileAsync.valueOrNull;

                var filtered = jobs.where((j) {
                  if (_searchFilter.isNotEmpty) {
                    final q = _searchFilter.toLowerCase();
                    final matches = j.title.toLowerCase().contains(q) ||
                        j.company.toLowerCase().contains(q) ||
                        (j.skills?.toLowerCase().contains(q) ?? false) ||
                        (j.location?.toLowerCase().contains(q) ?? false);
                    if (!matches) return false;
                  }

                  if (_selectedFilter == 'REMOTE') {
                    final isRemote = (j.location ?? '').toLowerCase().contains('remote') ||
                        (j.employmentType ?? '').toLowerCase().contains('remote');
                    if (!isRemote) return false;
                  } else if (_selectedFilter == 'SAVED') {
                    if (!j.isSaved) return false;
                  }

                  return true;
                }).toList();

                // Sort by match score descending
                filtered.sort((a, b) {
                  final matchA = JobMatchService.calculateMatch(job: a, profile: profile);
                  final matchB = JobMatchService.calculateMatch(job: b, profile: profile);
                  return matchB.matchPercentage.compareTo(matchA.matchPercentage);
                });

                if (_selectedFilter == 'STRONG_MATCH') {
                  filtered = filtered.where((j) {
                    final m = JobMatchService.calculateMatch(job: j, profile: profile);
                    return m.matchPercentage >= 80;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_outline, size: 48, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            'No jobs match your filter criteria',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap "Discover Live" to fetch real opportunities from RemoteOK and developer feeds tailored to your active resume.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final job = filtered[index];
                    final match = JobMatchService.calculateMatch(job: job, profile: profile);

                    return _buildJobCard(context, ref, job, match);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading jobs: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => setState(() => _selectedFilter = filterKey),
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    WidgetRef ref,
    Job job,
    JobMatchResult match,
  ) {
    final theme = Theme.of(context);
    final db = ref.read(databaseProvider);

    Color scoreColor;
    if (match.matchPercentage >= 80) {
      scoreColor = Colors.green.shade600;
    } else if (match.matchPercentage >= 50) {
      scoreColor = Colors.amber.shade700;
    } else {
      scoreColor = Colors.blueGrey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetailsScreen(jobId: job.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${job.company} • ${job.location ?? "Remote"}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 14, color: scoreColor),
                        const SizedBox(width: 4),
                        Text(
                          '${match.matchPercentage}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (job.skills != null && job.skills!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: job.skills!
                      .split(',')
                      .take(5)
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s.trim(),
                              style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                            ),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (job.salary != null && job.salary!.isNotEmpty)
                    Text(
                      job.salary!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      job.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: job.isSaved ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () {
                      db.toggleJobSaved(job.id, !job.isSaved);
                    },
                    tooltip: job.isSaved ? 'Remove Bookmark' : 'Bookmark Job',
                  ),
                  IconButton(
                    icon: const Icon(Icons.psychology_outlined, size: 20),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => JobAiAnalysisDialog(job: job),
                      );
                    },
                    tooltip: 'AI Fit Analysis',
                  ),
                  if (job.url != null && job.url!.isNotEmpty)
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('Apply'),
                      onPressed: () async {
                        final uri = Uri.tryParse(job.url!);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
