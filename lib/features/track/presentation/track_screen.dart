import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/track_providers.dart';
import 'add_edit_dsa_dialog.dart';
import 'add_edit_expense_dialog.dart';
import 'add_edit_income_dialog.dart';
import 'add_edit_weight_dialog.dart';
import 'add_edit_workout_dialog.dart';
import 'dsa_problem_details_screen.dart';
import 'finance_csv_export_dialog.dart';
import 'workout_details_screen.dart';

class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({super.key});

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isSyncingApas = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track & Discipline'),
        actions: [
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
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.code, size: 18), text: 'DSA Tracker'),
            Tab(icon: Icon(Icons.fitness_center_outlined, size: 18), text: 'Fitness'),
            Tab(icon: Icon(Icons.account_balance_wallet_outlined, size: 18), text: 'Finance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(theme),
          _buildDSATab(theme),
          _buildFitnessTab(theme),
          _buildFinanceTab(theme),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. OVERVIEW TAB
  // ===========================================================================
  Widget _buildOverviewTab(ThemeData theme) {
    final snapshot = ref.watch(trackSnapshotProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'TRACKING COMMAND CENTER',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),

        // DSA Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _tabController.animateTo(1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.code, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('DSA Problem Tracker', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          '${snapshot.dsaSolved}',
                          'Solved Problems',
                          Icons.check_circle_outline,
                          Colors.green,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          '${snapshot.dsaRevisionDue}',
                          'Revisions Due',
                          Icons.alarm,
                          snapshot.dsaRevisionDue > 0 ? Colors.red : Colors.grey,
                          theme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Fitness Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _tabController.animateTo(2),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fitness_center_outlined, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Fitness & Body Weight', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          snapshot.latestWeight != null ? '${snapshot.latestWeight!.toStringAsFixed(1)} kg' : 'Not logged',
                          snapshot.latestWeightDate != null ? DateFormatter.formatDate(snapshot.latestWeightDate) : 'Latest Weight',
                          Icons.monitor_weight_outlined,
                          Colors.purple,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          snapshot.recentWorkoutName ?? 'No sessions',
                          snapshot.recentWorkoutDate != null ? DateFormatter.formatDate(snapshot.recentWorkoutDate) : 'Recent Workout',
                          Icons.fitness_center,
                          Colors.orange.shade800,
                          theme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Finance Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _tabController.animateTo(3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Finance Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          '\$${snapshot.currentMonthIncome.toStringAsFixed(0)}',
                          'Month Income',
                          Icons.arrow_downward,
                          Colors.green,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          '\$${snapshot.currentMonthExpenses.toStringAsFixed(0)}',
                          'Month Expenses',
                          Icons.arrow_upward,
                          Colors.red,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          '\$${snapshot.currentMonthSavings.toStringAsFixed(0)}',
                          'Net Savings',
                          Icons.savings_outlined,
                          snapshot.currentMonthSavings >= 0 ? Colors.teal : Colors.deepOrange,
                          theme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. DSA TRACKER TAB
  // ===========================================================================
  Widget _buildDSATab(ThemeData theme) {
    final stats = ref.watch(dsaDashboardStatsProvider);
    final problems = ref.watch(filteredDSAProblemsProvider);
    final currentTopic = ref.watch(dsaTopicFilterProvider);
    final currentDiff = ref.watch(dsaDifficultyFilterProvider);
    final currentStatus = ref.watch(dsaStatusFilterProvider);
    final sort = ref.watch(dsaSortOptionProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(context: context, builder: (_) => const AddEditDSADialog());
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Problem'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total', '${stats.total}', theme.colorScheme.primary, theme),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Solved', '${stats.solved}', Colors.green, theme),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Attempted', '${stats.attempted}', Colors.orange.shade800, theme),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Revision Due', '${stats.revisionDue}', stats.revisionDue > 0 ? Colors.red : Colors.grey, theme),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // APAS LeetCode Integration Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'APAS LeetCode Problem Bank',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Sync 3,600+ LeetCode problems with solutions & company tags',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSyncingApas
                      ? null
                      : () async {
                          setState(() => _isSyncingApas = true);
                          try {
                            final count = await ref
                                .read(apasDsaServiceProvider)
                                .syncProblemsToDatabase(limit: 30);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    count > 0
                                        ? 'Successfully synced $count new problems from APAS LeetCode!'
                                        : 'All top APAS LeetCode problems are already up to date.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('APAS Sync failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isSyncingApas = false);
                            }
                          }
                        },
                  icon: _isSyncingApas
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync, size: 16),
                  label: Text(_isSyncingApas ? 'Syncing...' : 'Sync APAS'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search DSA problems, topics, algorithms...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            onChanged: (val) => ref.read(dsaSearchQueryProvider.notifier).state = val,
          ),
          const SizedBox(height: 10),

          // Topic Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Topics'),
                  selected: currentTopic == 'all',
                  onSelected: (_) => ref.read(dsaTopicFilterProvider.notifier).state = 'all',
                ),
                ...dsaTopics.map((topic) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      label: Text(topic),
                      selected: currentTopic.toLowerCase() == topic.toLowerCase(),
                      onSelected: (selected) {
                        ref.read(dsaTopicFilterProvider.notifier).state = selected ? topic : 'all';
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Difficulty & Status Filter Row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: currentDiff,
                  decoration: const InputDecoration(isDense: true, labelText: 'Difficulty', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Difficulties')),
                    DropdownMenuItem(value: 'EASY', child: Text('Easy')),
                    DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                    DropdownMenuItem(value: 'HARD', child: Text('Hard')),
                  ],
                  onChanged: (val) {
                    if (val != null) ref.read(dsaDifficultyFilterProvider.notifier).state = val;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: currentStatus,
                  decoration: const InputDecoration(isDense: true, labelText: 'Status', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'TODO', child: Text('To Do')),
                    DropdownMenuItem(value: 'ATTEMPTED', child: Text('Attempted')),
                    DropdownMenuItem(value: 'SOLVED', child: Text('Solved')),
                    DropdownMenuItem(value: 'NEEDS_REVISION', child: Text('Needs Revision')),
                  ],
                  onChanged: (val) {
                    if (val != null) ref.read(dsaStatusFilterProvider.notifier).state = val;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<DSASortOption>(
                  value: sort,
                  decoration: const InputDecoration(isDense: true, labelText: 'Sort', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: DSASortOption.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) {
                    if (val != null) ref.read(dsaSortOptionProvider.notifier).state = val;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Problem List
          if (problems.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No DSA problems match your filters. Tap "Add Problem" to log your first solution!'),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: problems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final prob = problems[idx];
                final diff = DSADifficulty.fromString(prob.difficulty);
                final stat = DSAStatus.fromString(prob.status);

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DSAProblemDetailsScreen(problem: prob),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
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
                                      prob.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(prob.platform, style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                                        Text(' • ', style: TextStyle(color: theme.hintColor)),
                                        Text(prob.topic, style: TextStyle(fontSize: 12, color: theme.hintColor)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              _buildDifficultyChip(diff),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _buildStatusBadge(stat),
                                  const SizedBox(width: 8),
                                  Text('${prob.attempts} attempts', style: TextStyle(fontSize: 11, color: theme.hintColor)),
                                ],
                              ),
                              if (prob.revisionDate != null)
                                Row(
                                  children: [
                                    Icon(Icons.alarm, size: 13, color: prob.revisionDate!.isBefore(DateTime.now()) ? Colors.red : Colors.orange.shade800),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormatter.formatDate(prob.revisionDate),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: prob.revisionDate!.isBefore(DateTime.now()) ? Colors.red : Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
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
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. FITNESS TAB
  // ===========================================================================
  Widget _buildFitnessTab(ThemeData theme) {
    final workouts = ref.watch(workoutsStreamProvider).valueOrNull ?? [];
    final latestWeight = ref.watch(latestBodyWeightProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(context: context, builder: (_) => const AddEditWorkoutDialog());
        },
        icon: const Icon(Icons.fitness_center),
        label: const Text('Log Workout'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Body Weight Header Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.monitor_weight_outlined, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Body Weight Progression', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Log Weight'),
                        onPressed: () {
                          showDialog(context: context, builder: (_) => const AddEditWeightDialog());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              latestWeight != null ? '${latestWeight.weight.toStringAsFixed(1)} kg' : '--',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                            Text('Current Weight', style: TextStyle(fontSize: 11, color: theme.hintColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          latestWeight != null
                              ? 'Last weighed on ${DateFormatter.formatDate(latestWeight.date)}${latestWeight.note != null ? '\n"${latestWeight.note}"' : ''}'
                              : 'No body weight logged yet. Tap Log Weight to begin tracking.',
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Workout Logs Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WORKOUT LOGS (${workouts.length})',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.playlist_add, size: 20),
                tooltip: 'Quick Start Workout from Template',
                onSelected: (templateName) {
                  List<String> exercises = [];
                  if (templateName == 'Push - Chest/Shoulders/Triceps') {
                    exercises = ['Bench Press', 'Incline DB Press', 'Overhead DB Press', 'Lateral Raises', 'Tricep Pushdowns'];
                  } else if (templateName == 'Pull - Back/Biceps') {
                    exercises = ['Pull-ups / Lat Pulldown', 'Barbell Row', 'Face Pulls', 'Bicep Barbell Curls', 'Hammer Curls'];
                  } else if (templateName == 'Legs & Core') {
                    exercises = ['Barbell Squats', 'Romanian Deadlifts', 'Leg Press', 'Calf Raises', 'Hanging Leg Raises'];
                  }
                  showDialog(
                    context: context,
                    builder: (_) => AddEditWorkoutDialog(
                      initialTemplateName: templateName,
                      templateExercises: exercises,
                    ),
                  );
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'Push - Chest/Shoulders/Triceps', child: Text('Template: Push Day')),
                  PopupMenuItem(value: 'Pull - Back/Biceps', child: Text('Template: Pull Day')),
                  PopupMenuItem(value: 'Legs & Core', child: Text('Template: Legs & Core')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (workouts.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No workouts logged yet. Tap "Log Workout" or choose a template!'),
                ),
              ),
            )
          else
            ...workouts.map((w) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.fitness_center, color: theme.colorScheme.primary, size: 20),
                  ),
                  title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${DateFormatter.formatDate(w.date)}${w.duration != null ? ' • ${w.duration} mins' : ''}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => WorkoutDetailsScreen(workout: w)),
                    );
                  },
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. FINANCE TAB
  // ===========================================================================
  Widget _buildFinanceTab(ThemeData theme) {
    final summary = ref.watch(financeSummaryProvider);
    final expenses = ref.watch(filteredExpensesProvider);
    final incomes = ref.watch(filteredIncomesProvider);
    final selectedDate = ref.watch(financeSelectedDateProvider);
    final categoryFilter = ref.watch(expenseCategoryFilterProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(context: context, builder: (_) => const AddEditExpenseDialog());
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Month Selector Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  ref.read(financeSelectedDateProvider.notifier).state = DateTime(selectedDate.year, selectedDate.month - 1);
                },
              ),
              Text(
                '${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      ref.read(financeSelectedDateProvider.notifier).state = DateTime(selectedDate.year, selectedDate.month + 1);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: 'Export CSV',
                    onPressed: () {
                      showDialog(context: context, builder: (_) => const FinanceCsvExportDialog());
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Finance Summary Balance Cards
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildRevenueItem('Income', '\$${summary.monthIncome.toStringAsFixed(2)}', Colors.green, theme),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRevenueItem('Expenses', '\$${summary.monthExpenses.toStringAsFixed(2)}', Colors.red, theme),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRevenueItem('Savings', '\$${summary.netSavings.toStringAsFixed(2)}', summary.netSavings >= 0 ? Colors.teal : Colors.deepOrange, theme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('+ Add Income'),
                        onPressed: () {
                          showDialog(context: context, builder: (_) => const AddEditIncomeDialog());
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Expense Category Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Categories'),
                  selected: categoryFilter == 'all',
                  onSelected: (_) => ref.read(expenseCategoryFilterProvider.notifier).state = 'all',
                ),
                ...expenseCategories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: FilterChip(
                      label: Text(cat),
                      selected: categoryFilter.toLowerCase() == cat.toLowerCase(),
                      onSelected: (sel) {
                        ref.read(expenseCategoryFilterProvider.notifier).state = sel ? cat : 'all';
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Transactions Ledger
          Text(
            'EXPENSES (${expenses.length})',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),

          if (expenses.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No expenses logged for this month.')),
              ),
            )
          else
            ...expenses.map((exp) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withOpacity(0.15),
                    child: const Icon(Icons.arrow_upward, color: Colors.red, size: 18),
                  ),
                  title: Text(exp.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${exp.category} • ${DateFormatter.formatDate(exp.date)}'),
                  trailing: Text('-\$${exp.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14)),
                  onTap: () {
                    showDialog(context: context, builder: (_) => AddEditExpenseDialog(expenseToEdit: exp));
                  },
                ),
              );
            }),
          const SizedBox(height: 16),

          // Incomes Section
          Text(
            'INCOMES (${incomes.length})',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),

          if (incomes.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No income logged for this month.')),
              ),
            )
          else
            ...incomes.map((inc) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.15),
                    child: const Icon(Icons.arrow_downward, color: Colors.green, size: 18),
                  ),
                  title: Text(inc.source, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${inc.category} • ${DateFormatter.formatDate(inc.date)}'),
                  trailing: Text('+\$${inc.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
                  onTap: () {
                    showDialog(context: context, builder: (_) => AddEditIncomeDialog(incomeToEdit: inc));
                  },
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // Helper UI Builders
  Widget _buildMetricTile(String value, String label, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: theme.hintColor)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: theme.hintColor), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(DSADifficulty diff) {
    Color color;
    switch (diff) {
      case DSADifficulty.easy:
        color = Colors.green;
        break;
      case DSADifficulty.medium:
        color = Colors.orange.shade800;
        break;
      case DSADifficulty.hard:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(diff.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusBadge(DSAStatus status) {
    Color color;
    switch (status) {
      case DSAStatus.solved:
        color = Colors.green;
        break;
      case DSAStatus.attempted:
        color = Colors.orange.shade800;
        break;
      case DSAStatus.needsRevision:
        color = Colors.red;
        break;
      case DSAStatus.todo:
        color = Colors.blueGrey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRevenueItem(String label, String value, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: theme.hintColor)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }
}
