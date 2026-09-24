import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/priority_chip.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/work_providers.dart';
import 'add_edit_eod_dialog.dart';
import 'add_edit_project_dialog.dart';
import 'add_edit_task_dialog.dart';
import 'add_edit_thing_to_ask_dialog.dart';
import 'add_edit_work_note_dialog.dart';
import 'eod_history_screen.dart';
import 'project_details_screen.dart';
import 'work_note_details_screen.dart';

class WorkScreen extends ConsumerStatefulWidget {
  const WorkScreen({super.key});

  @override
  ConsumerState<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends ConsumerState<WorkScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _taskSearchController = TextEditingController();
  final TextEditingController _notesSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskSearchController.dispose();
    _notesSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = ref.watch(workSnapshotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Command Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu),
            tooltip: 'EOD History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EODHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Quick Add',
            onPressed: () => _showWorkQuickAdd(context),
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
                  const Text('Today'),
                  if (snapshot.todayTasksCount > 0 || snapshot.overdueTasksCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildCountBadge(
                      '${snapshot.todayTasksCount + snapshot.overdueTasksCount}',
                      snapshot.overdueTasksCount > 0 ? Colors.redAccent : theme.colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('Tasks'),
                  if (snapshot.todayTasksCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildCountBadge('${snapshot.todayTasksCount}', theme.colorScheme.secondary),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('Projects'),
                  if (snapshot.activeProjectsCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildCountBadge('${snapshot.activeProjectsCount}', const Color(0xFFF59E0B)),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Notes & Meetings'),
            Tab(
              child: Row(
                children: [
                  const Text('EOD Log'),
                  if (!snapshot.isTodayEodLogged) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('Things to Ask'),
                  if (snapshot.openQuestionsCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildCountBadge('${snapshot.openQuestionsCount}', Colors.pinkAccent),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayView(context, ref, theme),
          _buildTasksView(context, ref, theme),
          _buildProjectsView(context, ref, theme),
          _buildNotesView(context, ref, theme),
          _buildEODView(context, ref, theme),
          _buildThingsToAskView(context, ref, theme),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    return ListenableBuilder(
      listenable: _tabController,
      builder: (context, _) {
        switch (_tabController.index) {
          case 0:
          case 1:
            return FloatingActionButton.extended(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddEditTaskDialog(initialCategory: 'work'),
              ),
              icon: const Icon(Icons.add_task),
              label: const Text('New Task'),
            );
          case 2:
            return FloatingActionButton.extended(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddEditProjectDialog(),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New Project'),
            );
          case 3:
            return FloatingActionButton.extended(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddEditWorkNoteDialog(),
              ),
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('New Note'),
            );
          case 4:
            return FloatingActionButton.extended(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddEditEODDialog(),
              ),
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Log EOD'),
            );
          case 5:
            return FloatingActionButton.extended(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddEditThingToAskDialog(),
              ),
              icon: const Icon(Icons.question_answer_outlined),
              label: const Text('Add Question'),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildCountBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: TODAY'S WORK
  // ==========================================
  Widget _buildTodayView(BuildContext context, WidgetRef ref, ThemeData theme) {
    final todayTasks = ref.watch(todayTasksProvider);
    final overdueTasks = ref.watch(overdueTasksProvider);
    final inProgressTasks = ref.watch(inProgressTasksProvider);
    final todayEodAsync = ref.watch(todayEodNoteProvider);
    final todayEod = todayEodAsync.valueOrNull;
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(tasksStreamProvider),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormatter.formatDate(now),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Daily Focus & Standup',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    icon: Icon(
                      todayEod != null ? Icons.check_circle : Icons.edit_calendar,
                      size: 16,
                      color: todayEod != null ? const Color(0xFF10B981) : theme.colorScheme.primary,
                    ),
                    label: Text(
                      todayEod != null ? 'EOD Logged' : 'Log EOD',
                      style: TextStyle(
                        fontSize: 12,
                        color: todayEod != null ? const Color(0xFF10B981) : null,
                      ),
                    ),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AddEditEODDialog(existingNote: todayEod),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Overdue Tasks (If Any)
          if (overdueTasks.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.redAccent),
                const SizedBox(width: 6),
                Text(
                  'Overdue Tasks (${overdueTasks.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...overdueTasks.map((t) => _buildTaskItem(context, ref, t, theme, isOverdue: true)),
            const SizedBox(height: 16),
          ],

          // In Progress Tasks
          if (inProgressTasks.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.timelapse, size: 18, color: Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                Text(
                  'In Progress (${inProgressTasks.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...inProgressTasks.map((t) => _buildTaskItem(context, ref, t, theme)),
            const SizedBox(height: 16),
          ],

          // Today's Scheduled Tasks
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today’s Action Items (${todayTasks.length})',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Task', style: TextStyle(fontSize: 12)),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const AddEditTaskDialog(initialCategory: 'work'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (todayTasks.isEmpty && overdueTasks.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 40, color: Colors.green.withOpacity(0.6)),
                    const SizedBox(height: 10),
                    const Text(
                      'All caught up for today!',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No pending tasks scheduled for today. Add a new task or review projects.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            )
          else
            ...todayTasks.map((t) => _buildTaskItem(context, ref, t, theme)),

          const SizedBox(height: 20),

          // EOD Standup Snapshot
          Text(
            'Today’s EOD Standup',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (todayEod == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_note, color: Colors.purple, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EOD Log Pending',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Capture completed items, in-progress work, and blockers.',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const AddEditEODDialog(),
                      ),
                      child: const Text('Log Now'),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AddEditEODDialog(existingNote: todayEod),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                              SizedBox(width: 6),
                              Text(
                                'EOD Recorded for Today',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981)),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => AddEditEODDialog(existingNote: todayEod),
                            ),
                            child: const Text('Edit', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const Divider(height: 12),
                      Text(
                        'Completed: ${todayEod.completedWork}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'In Progress: ${todayEod.inProgressWork}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: WORK TASKS
  // ==========================================
  Widget _buildTasksView(BuildContext context, WidgetRef ref, ThemeData theme) {
    final tasks = ref.watch(filteredTasksProvider);
    final statusFilter = ref.watch(taskFilterStatusProvider);
    final priorityFilter = ref.watch(taskFilterPriorityProvider);
    final categoryFilter = ref.watch(taskFilterCategoryProvider);
    final sort = ref.watch(taskSortOptionProvider);
    final projects = ref.watch(projectsStreamProvider).valueOrNull ?? [];
    final selectedProject = ref.watch(taskFilterProjectProvider);

    return Column(
      children: [
        // Search & Filter Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _taskSearchController,
            decoration: InputDecoration(
              hintText: 'Search tasks by title or notes...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _taskSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _taskSearchController.clear();
                        ref.read(taskSearchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) => ref.read(taskSearchQueryProvider.notifier).state = val,
          ),
        ),

        // Horizontal Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Category filter
              DropdownButton<String>(
                value: categoryFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Contexts', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'work', child: Text('Work Only', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'personal', child: Text('Personal Only', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) ref.read(taskFilterCategoryProvider.notifier).state = val;
                },
              ),
              const SizedBox(width: 8),

              // Status Filter Chips
              FilterChip(
                label: const Text('All', style: TextStyle(fontSize: 12)),
                selected: statusFilter == 'all',
                onSelected: (_) => ref.read(taskFilterStatusProvider.notifier).state = 'all',
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('To Do', style: TextStyle(fontSize: 12)),
                selected: statusFilter == 'todo',
                onSelected: (_) => ref.read(taskFilterStatusProvider.notifier).state = 'todo',
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('In Progress', style: TextStyle(fontSize: 12)),
                selected: statusFilter == 'in_progress',
                onSelected: (_) => ref.read(taskFilterStatusProvider.notifier).state = 'in_progress',
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Completed', style: TextStyle(fontSize: 12)),
                selected: statusFilter == 'completed',
                onSelected: (_) => ref.read(taskFilterStatusProvider.notifier).state = 'completed',
              ),
              const SizedBox(width: 8),

              // Priority Filter
              DropdownButton<String>(
                value: priorityFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Priorities', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'high', child: Text('High Priority', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'medium', child: Text('Medium Priority', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'low', child: Text('Low Priority', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) ref.read(taskFilterPriorityProvider.notifier).state = val;
                },
              ),
              const SizedBox(width: 8),

              // Project Filter
              if (projects.isNotEmpty) ...[
                DropdownButton<String?>(
                  value: selectedProject,
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All Projects', style: TextStyle(fontSize: 12))),
                    ...projects.map((p) => DropdownMenuItem<String?>(
                          value: p.id,
                          child: Text(p.name, style: const TextStyle(fontSize: 12)),
                        )),
                  ],
                  onChanged: (val) => ref.read(taskFilterProjectProvider.notifier).state = val,
                ),
                const SizedBox(width: 8),
              ],

              // Sort
              DropdownButton<TaskSortOption>(
                value: sort,
                underline: const SizedBox(),
                items: TaskSortOption.values.map((s) {
                  return DropdownMenuItem(value: s, child: Text('Sort: ${s.label}', style: const TextStyle(fontSize: 12)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) ref.read(taskSortOptionProvider.notifier).state = val;
                },
              ),
            ],
          ),
        ),
        const Divider(height: 12),

        // Task List
        Expanded(
          child: tasks.isEmpty
              ? EmptyStateView(
                  icon: Icons.checklist_rtl,
                  title: 'No Tasks Found',
                  message: 'No tasks match your filter criteria or search keyword.',
                  actionLabel: '+ Create Task',
                  onAction: () => showDialog(
                    context: context,
                    builder: (_) => const AddEditTaskDialog(initialCategory: 'work'),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTaskItem(context, ref, task, theme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, Task task, ThemeData theme, {bool isOverdue = false}) {
    final isDone = task.status.toLowerCase() == 'completed';
    final priority = TaskPriority.fromString(task.priority);
    final projects = ref.watch(projectsStreamProvider).valueOrNull ?? [];
    final project = task.projectId != null ? projects.where((p) => p.id == task.projectId).firstOrNull : null;

    return Card(
      elevation: 0,
      color: isOverdue
          ? Colors.redAccent.withOpacity(0.06)
          : (isDone ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3) : theme.cardColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue
              ? Colors.redAccent.withOpacity(0.4)
              : theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showDialog(
          context: context,
          builder: (_) => AddEditTaskDialog(existingTask: task),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isDone
                      ? const Color(0xFF10B981)
                      : (isOverdue ? Colors.redAccent : theme.colorScheme.onSurface.withOpacity(0.5)),
                  size: 22,
                ),
                onPressed: () => ref.read(workRepositoryProvider).toggleTaskStatus(task),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? theme.colorScheme.onSurface.withOpacity(0.5) : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (task.dueDate != null) ...[
                          Icon(
                            Icons.event,
                            size: 12,
                            color: isOverdue ? Colors.redAccent : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.formatRelative(task.dueDate),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                              color: isOverdue ? Colors.redAccent : theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (project != null) ...[
                          Icon(Icons.folder_outlined, size: 12, color: theme.colorScheme.primary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              project.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (task.category.toLowerCase() == 'personal') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Personal', style: TextStyle(fontSize: 9, color: Colors.blueGrey)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PriorityChip(priority: priority),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (val) {
                  if (val == 'edit') {
                    showDialog(context: context, builder: (_) => AddEditTaskDialog(existingTask: task));
                  } else if (val == 'delete') {
                    ref.read(workRepositoryProvider).deleteTask(task.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: WORK PROJECTS
  // ==========================================
  Widget _buildProjectsView(BuildContext context, WidgetRef ref, ThemeData theme) {
    final projectsAsync = ref.watch(projectsStreamProvider);

    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) {
          return EmptyStateView(
            icon: Icons.folder_open,
            title: 'No Work Projects Yet',
            message: 'Create a project to group technical tasks, track completion progress, and document architecture.',
            actionLabel: '+ Create Project',
            onAction: () => showDialog(
              context: context,
              builder: (_) => const AddEditProjectDialog(),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: projects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final proj = projects[index];
            return _buildProjectCard(context, ref, proj, theme);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading projects: $e')),
    );
  }

  Widget _buildProjectCard(BuildContext context, WidgetRef ref, Project p, ThemeData theme) {
    final status = ProjectStatus.fromString(p.status);
    final tasksAsync = ref.watch(tasksByProjectProvider(p.id));
    final tasks = tasksAsync.valueOrNull ?? [];
    final completedTasks = tasks.where((t) => t.status.toLowerCase() == 'completed').length;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailsScreen(project: p, projectId: p.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  ProjectStatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 8),

              if (p.description != null && p.description!.isNotEmpty) ...[
                Text(
                  p.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress: ${(p.progress * 100).toInt()}% ($completedTasks/${tasks.length} tasks)',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  if (p.deadline != null)
                    Text(
                      'Deadline: ${DateFormatter.formatDate(p.deadline)}',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: p.progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),

              if (p.techStack != null && p.techStack!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: p.techStack!.split(',').take(4).map((tech) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(tech.trim(), style: const TextStyle(fontSize: 10)),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: NOTES & MEETINGS
  // ==========================================
  Widget _buildNotesView(BuildContext context, WidgetRef ref, ThemeData theme) {
    final notes = ref.watch(filteredWorkNotesProvider);
    final filterType = ref.watch(workNotesFilterTypeProvider);

    return Column(
      children: [
        // Search Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _notesSearchController,
            decoration: InputDecoration(
              hintText: 'Search notes by keyword or attendee...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _notesSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _notesSearchController.clear();
                        ref.read(workNotesSearchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) => ref.read(workNotesSearchQueryProvider.notifier).state = val,
          ),
        ),

        // Filter Type Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All Notes', style: TextStyle(fontSize: 12)),
                selected: filterType == 'all',
                onSelected: (_) => ref.read(workNotesFilterTypeProvider.notifier).state = 'all',
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Meetings', style: TextStyle(fontSize: 12)),
                selected: filterType == 'meeting',
                onSelected: (_) => ref.read(workNotesFilterTypeProvider.notifier).state = 'meeting',
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Technical', style: TextStyle(fontSize: 12)),
                selected: filterType == 'technical',
                onSelected: (_) => ref.read(workNotesFilterTypeProvider.notifier).state = 'technical',
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Runbooks', style: TextStyle(fontSize: 12)),
                selected: filterType == 'instruction',
                onSelected: (_) => ref.read(workNotesFilterTypeProvider.notifier).state = 'instruction',
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Investigations', style: TextStyle(fontSize: 12)),
                selected: filterType == 'investigation',
                onSelected: (_) => ref.read(workNotesFilterTypeProvider.notifier).state = 'investigation',
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('General', style: TextStyle(fontSize: 12)),
                selected: filterType == 'general',
                onSelected: (_) => ref.read(workNotesFilterTypeProvider.notifier).state = 'general',
              ),
            ],
          ),
        ),
        const Divider(height: 12),

        // Notes List
        Expanded(
          child: notes.isEmpty
              ? EmptyStateView(
                  icon: Icons.note_alt_outlined,
                  title: 'No Notes Recorded',
                  message: 'Capture meeting takeaways, technical architecture docs, runbooks, and bug investigations.',
                  actionLabel: '+ Create Note',
                  onAction: () => showDialog(
                    context: context,
                    builder: (_) => const AddEditWorkNoteDialog(),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _buildNoteCard(context, ref, note, theme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(BuildContext context, WidgetRef ref, WorkNote n, ThemeData theme) {
    final isMeeting = n.noteType.toLowerCase() == 'meeting';
    final actionItemsCount = (n.actionItems != null && n.actionItems!.trim().isNotEmpty)
        ? n.actionItems!.split('\n').where((l) => l.trim().isNotEmpty).length
        : 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkNoteDetailsScreen(note: n, noteId: n.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildNoteTypeBadge(n.noteType, theme),
                      if (isMeeting && n.meetingDate != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          DateFormatter.formatDate(n.meetingDate),
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    DateFormatter.formatRelative(n.updatedAt),
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                n.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                n.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.3,
                ),
              ),
              if (actionItemsCount > 0 || (n.participants != null && n.participants!.isNotEmpty)) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (actionItemsCount > 0) ...[
                      Icon(Icons.task_alt, size: 14, color: Colors.green.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '$actionItemsCount Action Items',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade600),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (n.participants != null && n.participants!.isNotEmpty) ...[
                      Icon(Icons.people_outline, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          n.participants!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTypeBadge(String type, ThemeData theme) {
    Color bg;
    Color fg;
    String label;

    switch (type.toLowerCase()) {
      case 'meeting':
        bg = Colors.blue.withOpacity(0.15);
        fg = Colors.blue;
        label = 'Meeting';
        break;
      case 'technical':
        bg = Colors.purple.withOpacity(0.15);
        fg = Colors.purple;
        label = 'Technical';
        break;
      case 'instruction':
        bg = Colors.orange.withOpacity(0.15);
        fg = Colors.orange;
        label = 'Runbook';
        break;
      case 'investigation':
        bg = Colors.red.withOpacity(0.15);
        fg = Colors.red;
        label = 'Bug / Issue';
        break;
      default:
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.primary;
        label = 'General';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  // ==========================================
  // TAB 4: EOD LOG
  // ==========================================
  Widget _buildEODView(BuildContext context, WidgetRef ref, ThemeData theme) {
    final todayEodAsync = ref.watch(todayEodNoteProvider);
    final todayEod = todayEodAsync.valueOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today’s EOD Standup',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(Icons.history, size: 16),
                label: const Text('Past EOD History'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EODHistoryScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (todayEod == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_calendar, color: Colors.purple, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No EOD Log Recorded for Today',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Document what you completed, what remains in progress, blockers, and tomorrow’s plan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Log Today’s EOD'),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const AddEditEODDialog(),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormatter.formatDate(todayEod.date),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit EOD',
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => AddEditEODDialog(existingNote: todayEod),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    _buildEODSectionTitle(theme, '1. Completed Today', Icons.check_circle_outline, const Color(0xFF10B981)),
                    const SizedBox(height: 6),
                    _buildEODTextBox(theme, todayEod.completedWork),
                    const SizedBox(height: 14),

                    _buildEODSectionTitle(theme, '2. In Progress / Worked On', Icons.timelapse, const Color(0xFF38BDF8)),
                    const SizedBox(height: 6),
                    _buildEODTextBox(theme, todayEod.inProgressWork),
                    const SizedBox(height: 14),

                    if (todayEod.blockers != null && todayEod.blockers!.trim().isNotEmpty) ...[
                      _buildEODSectionTitle(theme, '3. Blockers / Need Help', Icons.warning_amber_rounded, Colors.redAccent),
                      const SizedBox(height: 6),
                      _buildEODTextBox(theme, todayEod.blockers!),
                      const SizedBox(height: 14),
                    ],

                    if (todayEod.tomorrowPlan != null && todayEod.tomorrowPlan!.trim().isNotEmpty) ...[
                      _buildEODSectionTitle(theme, '4. Plan for Tomorrow', Icons.next_plan_outlined, const Color(0xFFF59E0B)),
                      const SizedBox(height: 6),
                      _buildEODTextBox(theme, todayEod.tomorrowPlan!),
                      const SizedBox(height: 14),
                    ],

                    if (todayEod.notes != null && todayEod.notes!.trim().isNotEmpty) ...[
                      _buildEODSectionTitle(theme, '5. Notes', Icons.notes, theme.colorScheme.primary),
                      const SizedBox(height: 6),
                      _buildEODTextBox(theme, todayEod.notes!),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEODSectionTitle(ThemeData theme, String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildEODTextBox(ThemeData theme, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
    );
  }

  // ==========================================
  // TAB 5: THINGS TO ASK
  // ==========================================
  Widget _buildThingsToAskView(BuildContext context, WidgetRef ref, ThemeData theme) {
    final openItems = ref.watch(openThingsToAskProvider);
    final resolvedItems = ref.watch(resolvedThingsToAskProvider);

    if (openItems.isEmpty && resolvedItems.isEmpty) {
      return EmptyStateView(
        icon: Icons.question_answer_outlined,
        title: 'No Questions Logged',
        message: 'Keep track of questions to ask your manager, team lead, or client during standup and 1:1 meetings.',
        actionLabel: '+ Add Thing to Ask',
        onAction: () => showDialog(
          context: context,
          builder: (_) => const AddEditThingToAskDialog(),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (openItems.isNotEmpty) ...[
          Text(
            'Open Questions & Blockers (${openItems.length})',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...openItems.map((item) => _buildQuestionItem(context, ref, item, theme, isOpen: true)),
          const SizedBox(height: 16),
        ],

        if (resolvedItems.isNotEmpty) ...[
          Text(
            'Resolved / Answered (${resolvedItems.length})',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 8),
          ...resolvedItems.map((item) => _buildQuestionItem(context, ref, item, theme, isOpen: false)),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildQuestionItem(BuildContext context, WidgetRef ref, ThingsToAsk item, ThemeData theme, {required bool isOpen}) {
    final isResolved = item.status.toLowerCase() == 'resolved';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showDialog(
          context: context,
          builder: (_) => AddEditThingToAskDialog(existingItem: item),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isResolved,
                onChanged: (val) {
                  ref.read(workRepositoryProvider).toggleThingToAsk(item.id, val ?? false);
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: isResolved ? TextDecoration.lineThrough : null,
                        color: isResolved ? theme.colorScheme.onSurface.withOpacity(0.5) : null,
                      ),
                    ),
                    if (item.description != null && item.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildPriorityBadge(item.priority),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (val) {
                  if (val == 'edit') {
                    showDialog(context: context, builder: (_) => AddEditThingToAskDialog(existingItem: item));
                  } else if (val == 'delete') {
                    ref.read(workRepositoryProvider).deleteThingToAsk(item.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color bg;
    Color fg;

    switch (priority.toLowerCase()) {
      case 'high':
        bg = Colors.red.withOpacity(0.15);
        fg = Colors.red;
        break;
      case 'low':
        bg = Colors.blueGrey.withOpacity(0.15);
        fg = Colors.blueGrey;
        break;
      default:
        bg = Colors.orange.withOpacity(0.15);
        fg = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  void _showWorkQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Quick Add to Work',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.add_task, color: Color(0xFF3B82F6)),
              title: const Text('New Work Task'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => const AddEditTaskDialog(initialCategory: 'work'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open, color: Color(0xFFF59E0B)),
              title: const Text('New Work Project'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => const AddEditProjectDialog());
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar, color: Color(0xFF8B5CF6)),
              title: const Text('Log Today’s EOD Note'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => const AddEditEODDialog());
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add_outlined, color: Colors.teal),
              title: const Text('New Meeting / Work Note'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => const AddEditWorkNoteDialog());
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_answer_outlined, color: Colors.pinkAccent),
              title: const Text('Add Thing to Ask (Standup / 1:1)'),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(context: context, builder: (_) => const AddEditThingToAskDialog());
              },
            ),
          ],
        ),
      ),
    );
  }
}
