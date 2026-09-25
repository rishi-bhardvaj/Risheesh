import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/career_providers.dart';
import 'add_edit_application_dialog.dart';
import 'add_edit_job_dialog.dart';
import 'add_edit_resume_dialog.dart';
import 'add_edit_saved_search_dialog.dart';
import 'application_details_screen.dart';
import 'job_details_screen.dart';
import 'resume_vault_view.dart';
import 'saved_searches_view.dart';
import 'widgets/job_ai_analysis_dialog.dart';
import 'widgets/resume_selector_banner.dart';

class CareerScreen extends ConsumerStatefulWidget {
  const CareerScreen({super.key});

  @override
  ConsumerState<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends ConsumerState<CareerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _jobSearchCtrl = TextEditingController();
  final TextEditingController _appSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jobSearchCtrl.dispose();
    _appSearchCtrl.dispose();
    super.dispose();
  }

  void _showJobFilterSheet(BuildContext context) {
    final currentFilter = ref.read(jobFilterProvider);
    var filterState = currentFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Jobs',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(jobFilterProvider.notifier).state = const JobFilterState();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Saved Only
                  CheckboxListTile(
                    title: const Text('Saved / Bookmarked Only'),
                    value: filterState.savedOnly,
                    onChanged: (val) {
                      setSheetState(() {
                        filterState = filterState.copyWith(savedOnly: val ?? false);
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Remote Preference
                  const Text('Work Location Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['remote', 'hybrid', 'on-site'].map((mode) {
                      final isSelected = filterState.remotePreference == mode;
                      return ChoiceChip(
                        label: Text(mode.toUpperCase()),
                        selected: isSelected,
                        onSelected: (sel) {
                          setSheetState(() {
                            filterState = filterState.copyWith(
                              remotePreference: sel ? mode : null,
                              clearRemotePreference: !sel,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Employment Type
                  const Text('Employment Type', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['Full-time', 'Contract', 'Part-time', 'Internship'].map((type) {
                      final isSelected = filterState.employmentType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (sel) {
                          setSheetState(() {
                            filterState = filterState.copyWith(
                              employmentType: sel ? type : null,
                              clearEmploymentType: !sel,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        ref.read(jobFilterProvider.notifier).state = filterState;
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(careerSnapshotProvider);
    final followUpsDue = ref.watch(followUpsDueTodayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Command Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_pin_outlined),
            tooltip: 'Career Profile',
            onPressed: () => context.push('/career/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.work_outline, size: 18),
                  const SizedBox(width: 6),
                  const Text('Jobs'),
                  if (stats.savedJobsCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildBadge('${stats.savedJobsCount}', Colors.blue),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.assignment_turned_in_outlined, size: 18),
                  const SizedBox(width: 6),
                  const Text('Applications'),
                  if (stats.activeApplicationsCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildBadge('${stats.activeApplicationsCount}', Colors.indigo),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.alarm_on_outlined, size: 18),
                  const SizedBox(width: 6),
                  const Text('Follow-ups'),
                  if (followUpsDue.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildBadge('${followUpsDue.length}', Colors.redAccent),
                  ],
                ],
              ),
            ),
            const Tab(icon: Icon(Icons.picture_as_pdf_outlined, size: 18), text: 'Resumes'),
            const Tab(icon: Icon(Icons.saved_search, size: 18), text: 'Searches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Jobs Tab
          _buildJobsTab(context),

          // 2. Applications Tab
          _buildApplicationsTab(context),

          // 3. Follow-ups Tab
          _buildFollowUpsTab(context),

          // 4. Resume Vault Tab
          const ResumeVaultView(),

          // 5. Saved Searches Tab
          SavedSearchesView(
            onRunSearch: () {
              _tabController.animateTo(0);
            },
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget? _buildFab(BuildContext context) {
    switch (_tabController.index) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const AddEditJobDialog(),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Job'),
        );
      case 1:
      case 2:
        return FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const AddEditApplicationDialog(),
            );
          },
          icon: const Icon(Icons.add_task),
          label: const Text('Log Application'),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const AddEditResumeDialog(),
            );
          },
          icon: const Icon(Icons.upload_file),
          label: const Text('Add Resume'),
        );
      case 4:
        return FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const AddEditSavedSearchDialog(),
            );
          },
          icon: const Icon(Icons.saved_search),
          label: const Text('New Search Preset'),
        );
      default:
        return null;
    }
  }

  // --- TAB 1: JOBS ---
  Widget _buildJobsTab(BuildContext context) {
    final theme = Theme.of(context);
    final jobs = ref.watch(filteredJobsProvider);
    final filter = ref.watch(jobFilterProvider);
    final currentSort = ref.watch(jobSortProvider);
    final discoveryState = ref.watch(liveDiscoveryProvider);

    return Column(
      children: [
        // Active Resume Context Banner
        const ResumeSelectorBanner(),

        // Search, Discover Live & Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: _jobSearchCtrl,
                  leading: const Icon(Icons.search),
                  hintText: 'Search title, company, skills...',
                  trailing: _jobSearchCtrl.text.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _jobSearchCtrl.clear();
                              ref.read(jobSearchQueryProvider.notifier).state = '';
                            },
                          ),
                        ]
                      : null,
                  onChanged: (val) {
                    ref.read(jobSearchQueryProvider.notifier).state = val;
                  },
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: discoveryState.isLoading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final res = await ref.read(liveDiscoveryProvider.notifier).discoverJobs();
                        if (res != null) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Discovered ${res.totalDiscovered} jobs: ${res.newJobsSaved} new saved, ${res.duplicatesSkipped} duplicates skipped.',
                              ),
                            ),
                          );
                        }
                      },
                icon: discoveryState.isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.radar, size: 18),
                label: Text(discoveryState.isLoading ? 'Discovering...' : 'Discover Live'),
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                icon: Badge(
                  isLabelVisible: filter.hasActiveFilters,
                  child: const Icon(Icons.filter_list, size: 20),
                ),
                tooltip: 'Filter Jobs',
                onPressed: () => _showJobFilterSheet(context),
              ),
              PopupMenuButton<JobSortOption>(
                icon: const Icon(Icons.sort, size: 20),
                tooltip: 'Sort Jobs',
                initialValue: currentSort,
                onSelected: (s) => ref.read(jobSortProvider.notifier).state = s,
                itemBuilder: (ctx) => JobSortOption.values
                    .map((opt) => PopupMenuItem(value: opt, child: Text(opt.label)))
                    .toList(),
              ),
            ],
          ),
        ),

        // Active Filter Chips
        if (filter.hasActiveFilters)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (filter.savedOnly)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        label: const Text('Saved Only'),
                        onDeleted: () => ref.read(jobFilterProvider.notifier).state = filter.copyWith(savedOnly: false),
                      ),
                    ),
                  if (filter.remotePreference != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        label: Text('Mode: ${filter.remotePreference!}'),
                        onDeleted: () => ref.read(jobFilterProvider.notifier).state = filter.copyWith(clearRemotePreference: true),
                      ),
                    ),
                  if (filter.employmentType != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InputChip(
                        label: Text(filter.employmentType!),
                        onDeleted: () => ref.read(jobFilterProvider.notifier).state = filter.copyWith(clearEmploymentType: true),
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Jobs List
        Expanded(
          child: jobs.isEmpty
              ? EmptyStateView(
                  icon: Icons.work_off_outlined,
                  title: 'No Jobs Found',
                  message: 'Tap "Discover Live" to fetch opportunities from RemoteOK and RSS feeds tailored to your active resume, or add manually.',
                  actionLabel: 'Discover Live Jobs',
                  onAction: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final res = await ref.read(liveDiscoveryProvider.notifier).discoverJobs();
                    if (res != null) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Discovered ${res.totalDiscovered} jobs: ${res.newJobsSaved} new saved, ${res.duplicatesSkipped} duplicates skipped.',
                          ),
                        ),
                      );
                    }
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: jobs.length,
                  itemBuilder: (ctx, index) {
                    final job = jobs[index];
                    final match = ref.watch(jobMatchProvider(job));

                    Color matchColor = Colors.grey;
                    if (match.matchPercentage >= 80) {
                      matchColor = Colors.green;
                    } else if (match.matchPercentage >= 50) {
                      matchColor = Colors.amber.shade800;
                    }

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: job.isSaved ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
                          width: job.isSaved ? 1.5 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Title, Company, Bookmark
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          job.title,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${job.company} • ${job.location ?? "Remote"}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: matchColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: matchColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bolt, size: 14, color: matchColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${match.matchPercentage}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: matchColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      job.isSaved ? Icons.bookmark : Icons.bookmark_border,
                                      color: job.isSaved ? theme.colorScheme.primary : null,
                                    ),
                                    onPressed: () {
                                      ref.read(databaseProvider).toggleJobSaved(job.id, !job.isSaved);
                                    },
                                  ),
                                ],
                              ),
                              if (job.skills != null && job.skills!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: job.skills!
                                      .split(',')
                                      .take(4)
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
                              const Divider(height: 1),
                              const SizedBox(height: 8),

                              // Actions Row: AI Analysis, Apply, Track Application
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
                                    icon: const Icon(Icons.psychology_outlined, size: 20),
                                    tooltip: 'AI Description Analysis',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => JobAiAnalysisDialog(job: job),
                                      );
                                    },
                                  ),
                                  if (job.url != null && job.url!.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.open_in_new, size: 18),
                                      tooltip: 'Apply Online',
                                      onPressed: () async {
                                        final uri = Uri.tryParse(job.url!);
                                        if (uri != null && await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                    ),
                                  TextButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AddEditApplicationDialog(initialJob: job),
                                      );
                                    },
                                    icon: const Icon(Icons.send, size: 16),
                                    label: const Text('Track'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 2: APPLICATIONS ---
  Widget _buildApplicationsTab(BuildContext context) {
    final theme = Theme.of(context);
    final apps = ref.watch(filteredApplicationsProvider);
    final selectedStatus = ref.watch(applicationFilterStatusProvider);
    final currentSort = ref.watch(applicationSortProvider);

    return Column(
      children: [
        // Search & Sort Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: _appSearchCtrl,
                  leading: const Icon(Icons.search),
                  hintText: 'Search company, role, recruiter...',
                  trailing: _appSearchCtrl.text.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _appSearchCtrl.clear();
                              ref.read(applicationSearchQueryProvider.notifier).state = '';
                            },
                          ),
                        ]
                      : null,
                  onChanged: (val) {
                    ref.read(applicationSearchQueryProvider.notifier).state = val;
                  },
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<ApplicationSortOption>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort Applications',
                initialValue: currentSort,
                onSelected: (s) => ref.read(applicationSortProvider.notifier).state = s,
                itemBuilder: (ctx) => ApplicationSortOption.values
                    .map((opt) => PopupMenuItem(value: opt, child: Text(opt.label)))
                    .toList(),
              ),
            ],
          ),
        ),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: selectedStatus == 'all',
                onSelected: (sel) {
                  if (sel) ref.read(applicationFilterStatusProvider.notifier).state = 'all';
                },
              ),
              const SizedBox(width: 6),
              ...ApplicationStatus.values.map((s) {
                final isSelected = selectedStatus == s.name;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s.label),
                    selected: isSelected,
                    onSelected: (sel) {
                      ref.read(applicationFilterStatusProvider.notifier).state = sel ? s.name : 'all';
                    },
                  ),
                );
              }),
            ],
          ),
        ),

        // Applications List
        Expanded(
          child: apps.isEmpty
              ? EmptyStateView(
                  icon: Icons.assignment_outlined,
                  title: 'No Applications Found',
                  message: 'Track every application, stage, recruiter contact, and follow-up timeline.',
                  actionLabel: 'Log Application',
                  onAction: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddEditApplicationDialog(),
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: apps.length,
                  itemBuilder: (ctx, index) {
                    final app = apps[index];

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ApplicationDetailsScreen(application: app)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
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
                                          app.role,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          app.company,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(status: app.status),
                                ],
                              ),
                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 14, color: theme.hintColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    app.appliedAt != null
                                        ? 'Applied: ${DateFormatter.formatRelative(app.appliedAt!)}'
                                        : 'Created: ${DateFormatter.formatRelative(app.createdAt)}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  if (app.followUpDate != null) ...[
                                    const Spacer(),
                                    Icon(
                                      Icons.alarm,
                                      size: 14,
                                      color: _isOverdue(app.followUpDate!) ? Colors.red : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Follow-up: ${DateFormatter.formatDate(app.followUpDate!)}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: _isOverdue(app.followUpDate!) ? Colors.red : Colors.orange.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 3: FOLLOW-UPS ---
  Widget _buildFollowUpsTab(BuildContext context) {
    final theme = Theme.of(context);
    final followUps = ref.watch(followUpsDueTodayProvider);

    if (followUps.isEmpty) {
      return EmptyStateView(
        icon: Icons.check_circle_outline,
        title: 'All Follow-ups Clear',
        message: 'No pending job application follow-ups scheduled for today.',
        actionLabel: 'View All Applications',
        onAction: () => _tabController.animateTo(1),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: followUps.length,
      itemBuilder: (ctx, index) {
        final app = followUps[index];
        final isPast = app.followUpDate != null && _isOverdue(app.followUpDate!);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isPast ? Colors.red.withOpacity(0.5) : Colors.orange.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isPast ? Colors.red : Colors.orange).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPast ? Icons.warning_amber_rounded : Icons.alarm,
                            size: 14,
                            color: isPast ? Colors.red : Colors.orange.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPast ? 'OVERDUE FOLLOW-UP' : 'FOLLOW-UP TODAY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPast ? Colors.red.shade800 : Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (app.followUpDate != null)
                      Text(
                        DateFormatter.formatDate(app.followUpDate!),
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  app.role,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  app.company,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ApplicationDetailsScreen(application: app)),
                        );
                      },
                      child: const Text('View Application Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isOverdue(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }
}
