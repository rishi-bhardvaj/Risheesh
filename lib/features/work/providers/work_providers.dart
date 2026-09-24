import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';

// --- Tasks Streams ---
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTasks();
});

final taskByIdProvider = StreamProvider.family<Task?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.tasks)..where((t) => t.id.equals(id))).watchSingleOrNull();
});

final tasksByProjectProvider = StreamProvider.family<List<Task>, String>((ref, projectId) {
  final db = ref.watch(databaseProvider);
  return db.watchTasksByProject(projectId);
});

// --- Filter and Sort State for Tasks ---
enum TaskSortOption {
  dueDate('Due Date'),
  priority('Priority'),
  recentlyCreated('Recently Created'),
  title('Title (A-Z)');

  final String label;
  const TaskSortOption(this.label);
}

final taskSearchQueryProvider = StateProvider<String>((ref) => '');
final taskFilterStatusProvider = StateProvider<String>((ref) => 'all'); // 'all', 'todo', 'in_progress', 'completed'
final taskFilterPriorityProvider = StateProvider<String>((ref) => 'all'); // 'all', 'high', 'medium', 'low'
final taskFilterProjectProvider = StateProvider<String?>((ref) => null); // null for all, or projectId
final taskFilterCategoryProvider = StateProvider<String>((ref) => 'all'); // 'all', 'work', 'personal'
final taskSortOptionProvider = StateProvider<TaskSortOption>((ref) => TaskSortOption.dueDate);

// --- Filtered Tasks ---
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final query = ref.watch(taskSearchQueryProvider).trim().toLowerCase();
  final statusFilter = ref.watch(taskFilterStatusProvider);
  final priorityFilter = ref.watch(taskFilterPriorityProvider);
  final projectFilter = ref.watch(taskFilterProjectProvider);
  final categoryFilter = ref.watch(taskFilterCategoryProvider);
  final sort = ref.watch(taskSortOptionProvider);

  return tasksAsync.maybeWhen(
    data: (tasks) {
      var list = List<Task>.from(tasks);

      // Category filter
      if (categoryFilter != 'all') {
        list = list.where((t) => t.category.toLowerCase() == categoryFilter).toList();
      }

      // Status filter
      if (statusFilter != 'all') {
        list = list.where((t) => t.status.toLowerCase() == statusFilter).toList();
      }

      // Priority filter
      if (priorityFilter != 'all') {
        list = list.where((t) => t.priority.toLowerCase() == priorityFilter).toList();
      }

      // Project filter
      if (projectFilter != null && projectFilter.isNotEmpty) {
        list = list.where((t) => t.projectId == projectFilter).toList();
      }

      // Search query
      if (query.isNotEmpty) {
        list = list.where((t) {
          final title = t.title.toLowerCase();
          final desc = (t.description ?? '').toLowerCase();
          final notes = (t.notes ?? '').toLowerCase();
          return title.contains(query) || desc.contains(query) || notes.contains(query);
        }).toList();
      }

      // Sorting
      switch (sort) {
        case TaskSortOption.dueDate:
          list.sort((a, b) {
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          });
          break;
        case TaskSortOption.priority:
          final priorityWeight = {'high': 3, 'medium': 2, 'low': 1};
          list.sort((a, b) {
            final wA = priorityWeight[a.priority.toLowerCase()] ?? 0;
            final wB = priorityWeight[b.priority.toLowerCase()] ?? 0;
            return wB.compareTo(wA);
          });
          break;
        case TaskSortOption.recentlyCreated:
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case TaskSortOption.title:
          list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          break;
      }

      return list;
    },
    orElse: () => [],
  );
});

// --- Focus Tasks Providers for Today ---
final todayTasksProvider = Provider<List<Task>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final tasks = tasksAsync.valueOrNull ?? [];
  final now = DateTime.now();

  return tasks.where((t) {
    if (t.status.toLowerCase() == 'completed') return false;
    if (t.dueDate == null) return true; // Include unscheduled tasks in active pool
    return t.dueDate!.year == now.year && t.dueDate!.month == now.month && t.dueDate!.day == now.day;
  }).toList();
});

final inProgressTasksProvider = Provider<List<Task>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final tasks = tasksAsync.valueOrNull ?? [];
  return tasks.where((t) => t.status.toLowerCase() == 'in_progress').toList();
});

final overdueTasksProvider = Provider<List<Task>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final tasks = tasksAsync.valueOrNull ?? [];
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);

  return tasks.where((t) {
    if (t.status.toLowerCase() == 'completed' || t.dueDate == null) return false;
    return t.dueDate!.isBefore(startOfToday);
  }).toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
});

final upcomingTasksProvider = Provider<List<Task>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final tasks = tasksAsync.valueOrNull ?? [];
  final now = DateTime.now();
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return tasks.where((t) {
    if (t.status.toLowerCase() == 'completed' || t.dueDate == null) return false;
    return t.dueDate!.isAfter(endOfToday);
  }).toList()
    ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
});

// --- Projects Stream ---
final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllProjects();
});

final projectByIdProvider = StreamProvider.family<Project?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.projects)..where((p) => p.id.equals(id))).watchSingleOrNull();
});

final activeProjectsProvider = Provider<List<Project>>((ref) {
  final projects = ref.watch(projectsStreamProvider).valueOrNull ?? [];
  return projects.where((p) {
    final s = p.status.toLowerCase();
    return s == 'in_progress' || s == 'planned' || s == 'idea';
  }).toList();
});

// --- EOD Notes Streams ---
final eodNotesStreamProvider = StreamProvider<List<EODNote>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllEODNotes();
});

final todayEodNoteProvider = StreamProvider<EODNote?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchEODNoteForDate(DateTime.now());
});

final eodNoteByIdProvider = StreamProvider.family<EODNote?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.eODNotes)..where((e) => e.id.equals(id))).watchSingleOrNull();
});

// --- Things to Ask Streams ---
final thingsToAskStreamProvider = StreamProvider<List<ThingsToAsk>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllThingsToAsk();
});

final openThingsToAskProvider = Provider<List<ThingsToAsk>>((ref) {
  final items = ref.watch(thingsToAskStreamProvider).valueOrNull ?? [];
  return items.where((i) => i.status.toLowerCase() == 'open').toList();
});

final resolvedThingsToAskProvider = Provider<List<ThingsToAsk>>((ref) {
  final items = ref.watch(thingsToAskStreamProvider).valueOrNull ?? [];
  return items.where((i) => i.status.toLowerCase() == 'resolved').toList();
});

// --- Work Notes & Meeting Notes Streams ---
final workNotesStreamProvider = StreamProvider<List<WorkNote>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllWorkNotes();
});

final workNoteByIdProvider = StreamProvider.family<WorkNote?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.workNotes)..where((w) => w.id.equals(id))).watchSingleOrNull();
});

final workNotesSearchQueryProvider = StateProvider<String>((ref) => '');
final workNotesFilterTypeProvider = StateProvider<String>((ref) => 'all'); // 'all', 'general', 'meeting', 'technical', 'runbook', 'bug'

final filteredWorkNotesProvider = Provider<List<WorkNote>>((ref) {
  final notesAsync = ref.watch(workNotesStreamProvider);
  final query = ref.watch(workNotesSearchQueryProvider).trim().toLowerCase();
  final typeFilter = ref.watch(workNotesFilterTypeProvider);

  return notesAsync.maybeWhen(
    data: (notes) {
      var list = List<WorkNote>.from(notes);

      if (typeFilter != 'all') {
        list = list.where((n) => n.noteType.toLowerCase() == typeFilter).toList();
      }

      if (query.isNotEmpty) {
        list = list.where((n) {
          final title = n.title.toLowerCase();
          final content = n.content.toLowerCase();
          final participants = (n.participants ?? '').toLowerCase();
          final actionItems = (n.actionItems ?? '').toLowerCase();
          return title.contains(query) || content.contains(query) || participants.contains(query) || actionItems.contains(query);
        }).toList();
      }

      return list;
    },
    orElse: () => [],
  );
});

// --- Task Summary Statistics ---
class TaskSummary {
  final int total;
  final int completed;
  final int inProgress;
  final int pending;
  final int overdue;

  const TaskSummary({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
    required this.overdue,
  });
}

final taskSummaryProvider = Provider<TaskSummary>((ref) {
  final tasks = ref.watch(tasksStreamProvider).valueOrNull ?? [];
  final overdue = ref.watch(overdueTasksProvider);

  final total = tasks.length;
  final completed = tasks.where((t) => t.status.toLowerCase() == 'completed').length;
  final inProgress = tasks.where((t) => t.status.toLowerCase() == 'in_progress').length;
  final pending = total - completed;

  return TaskSummary(
    total: total,
    completed: completed,
    inProgress: inProgress,
    pending: pending,
    overdue: overdue.length,
  );
});

// --- Work Snapshot Data (For Work Dashboard & Home Integration) ---
class WorkSnapshotData {
  final int todayTasksCount;
  final int overdueTasksCount;
  final int inProgressTasksCount;
  final int activeProjectsCount;
  final bool isTodayEodLogged;
  final int openQuestionsCount;

  const WorkSnapshotData({
    required this.todayTasksCount,
    required this.overdueTasksCount,
    required this.inProgressTasksCount,
    required this.activeProjectsCount,
    required this.isTodayEodLogged,
    required this.openQuestionsCount,
  });
}

final workSnapshotProvider = Provider<WorkSnapshotData>((ref) {
  final todayTasks = ref.watch(todayTasksProvider);
  final overdueTasks = ref.watch(overdueTasksProvider);
  final inProgressTasks = ref.watch(inProgressTasksProvider);
  final activeProjects = ref.watch(activeProjectsProvider);
  final todayEod = ref.watch(todayEodNoteProvider).valueOrNull;
  final openQuestions = ref.watch(openThingsToAskProvider);

  return WorkSnapshotData(
    todayTasksCount: todayTasks.length,
    overdueTasksCount: overdueTasks.length,
    inProgressTasksCount: inProgressTasks.length,
    activeProjectsCount: activeProjects.length,
    isTodayEodLogged: todayEod != null,
    openQuestionsCount: openQuestions.length,
  );
});

// --- Work Repository ---
class WorkRepository {
  final AppDatabase db;
  static const _uuid = Uuid();

  WorkRepository(this.db);

  // --- Task Methods ---
  Future<void> addTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.todo,
    String category = 'work',
    String? projectId,
    DateTime? dueDate,
    String? notes,
  }) async {
    final now = DateTime.now();
    final companion = TasksCompanion(
      id: Value(_uuid.v4()),
      title: Value(title.trim()),
      description: Value(description?.trim().isEmpty == true ? null : description?.trim()),
      priority: Value(priority.name),
      status: Value(status.name),
      category: Value(category),
      projectId: Value(projectId),
      dueDate: Value(dueDate),
      notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await db.insertTask(companion);
  }

  Future<void> updateTask({
    required String id,
    required String title,
    String? description,
    required TaskPriority priority,
    required TaskStatus status,
    String category = 'work',
    String? projectId,
    DateTime? dueDate,
    String? notes,
  }) async {
    final companion = TasksCompanion(
      id: Value(id),
      title: Value(title.trim()),
      description: Value(description?.trim().isEmpty == true ? null : description?.trim()),
      priority: Value(priority.name),
      status: Value(status.name),
      category: Value(category),
      projectId: Value(projectId),
      dueDate: Value(dueDate),
      notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      updatedAt: Value(DateTime.now()),
    );
    await db.updateTask(companion);
  }

  Future<void> toggleTaskStatus(Task task) async {
    final newStatus = task.status.toLowerCase() == 'completed' ? 'todo' : 'completed';
    final companion = TasksCompanion(
      id: Value(task.id),
      title: Value(task.title),
      description: Value(task.description),
      priority: Value(task.priority),
      status: Value(newStatus),
      category: Value(task.category),
      projectId: Value(task.projectId),
      dueDate: Value(task.dueDate),
      notes: Value(task.notes),
      createdAt: Value(task.createdAt),
      updatedAt: Value(DateTime.now()),
    );
    await db.updateTask(companion);
  }

  Future<void> deleteTask(String id) => db.deleteTask(id);

  // --- Project Methods ---
  Future<void> addProject({
    required String name,
    String? description,
    ProjectStatus status = ProjectStatus.planned,
    double progress = 0.0,
    String? techStack,
    String? githubUrl,
    String? liveUrl,
    DateTime? deadline,
    String? notes,
  }) async {
    final now = DateTime.now();
    final companion = ProjectsCompanion(
      id: Value(_uuid.v4()),
      name: Value(name.trim()),
      description: Value(description?.trim().isEmpty == true ? null : description?.trim()),
      status: Value(status.name),
      progress: Value(progress.clamp(0.0, 1.0)),
      techStack: Value(techStack?.trim().isEmpty == true ? null : techStack?.trim()),
      githubUrl: Value(githubUrl?.trim().isEmpty == true ? null : githubUrl?.trim()),
      liveUrl: Value(liveUrl?.trim().isEmpty == true ? null : liveUrl?.trim()),
      deadline: Value(deadline),
      notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await db.insertProject(companion);
  }

  Future<void> updateProject({
    required String id,
    required String name,
    String? description,
    required ProjectStatus status,
    required double progress,
    String? techStack,
    String? githubUrl,
    String? liveUrl,
    DateTime? deadline,
    String? notes,
  }) async {
    final companion = ProjectsCompanion(
      id: Value(id),
      name: Value(name.trim()),
      description: Value(description?.trim().isEmpty == true ? null : description?.trim()),
      status: Value(status.name),
      progress: Value(progress.clamp(0.0, 1.0)),
      techStack: Value(techStack?.trim().isEmpty == true ? null : techStack?.trim()),
      githubUrl: Value(githubUrl?.trim().isEmpty == true ? null : githubUrl?.trim()),
      liveUrl: Value(liveUrl?.trim().isEmpty == true ? null : liveUrl?.trim()),
      deadline: Value(deadline),
      notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      updatedAt: Value(DateTime.now()),
    );
    await db.updateProject(companion);
  }

  Future<void> deleteProject(String id) => db.deleteProject(id);

  // --- EOD Methods ---
  Future<void> saveEODNote({
    String? existingId,
    DateTime? date,
    required String completedWork,
    required String inProgressWork,
    String? blockers,
    String? tomorrowPlan,
    String? notes,
  }) async {
    final targetDate = date ?? DateTime.now();
    final now = DateTime.now();

    // Check if EOD exists for this date
    final existing = existingId != null
        ? await db.getEODNoteById(existingId)
        : await db.getEODNoteForDate(targetDate);

    if (existing != null) {
      final companion = EODNotesCompanion(
        id: Value(existing.id),
        date: Value(existing.date),
        completedWork: Value(completedWork.trim()),
        inProgressWork: Value(inProgressWork.trim()),
        blockers: Value(blockers?.trim().isEmpty == true ? null : blockers?.trim()),
        tomorrowPlan: Value(tomorrowPlan?.trim().isEmpty == true ? null : tomorrowPlan?.trim()),
        notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
        createdAt: Value(existing.createdAt),
        updatedAt: Value(now),
      );
      await db.updateEODNote(companion);
    } else {
      final companion = EODNotesCompanion(
        id: Value(_uuid.v4()),
        date: Value(targetDate),
        completedWork: Value(completedWork.trim()),
        inProgressWork: Value(inProgressWork.trim()),
        blockers: Value(blockers?.trim().isEmpty == true ? null : blockers?.trim()),
        tomorrowPlan: Value(tomorrowPlan?.trim().isEmpty == true ? null : tomorrowPlan?.trim()),
        notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
        createdAt: Value(now),
        updatedAt: Value(now),
      );
      await db.insertEODNote(companion);
    }
  }

  Future<void> deleteEODNote(String id) => db.deleteEODNote(id);

  // --- Things to Ask Methods ---
  Future<void> addThingToAsk({
    required String title,
    String? description,
    String priority = 'medium',
  }) async {
    final now = DateTime.now();
    final companion = ThingsToAsksCompanion(
      id: Value(_uuid.v4()),
      title: Value(title.trim()),
      description: Value(description?.trim().isEmpty == true ? null : description?.trim()),
      priority: Value(priority),
      status: const Value('open'),
      createdAt: Value(now),
    );
    await db.insertThingToAsk(companion);
  }

  Future<void> updateThingToAsk({
    required String id,
    required String title,
    String? description,
    required String priority,
    required String status,
  }) async {
    final companion = ThingsToAsksCompanion(
      id: Value(id),
      title: Value(title.trim()),
      description: Value(description?.trim().isEmpty == true ? null : description?.trim()),
      priority: Value(priority),
      status: Value(status),
      completedAt: Value(status == 'resolved' ? DateTime.now() : null),
    );
    await db.updateThingToAsk(companion);
  }

  Future<void> toggleThingToAsk(String id, bool resolve) => db.toggleThingToAskStatus(id, resolve);
  Future<void> deleteThingToAsk(String id) => db.deleteThingToAsk(id);

  // --- Work Notes Methods ---
  Future<void> addWorkNote({
    required String title,
    required String content,
    String noteType = 'general',
    String? projectId,
    DateTime? meetingDate,
    String? participants,
    String? actionItems,
  }) async {
    final now = DateTime.now();
    final companion = WorkNotesCompanion(
      id: Value(_uuid.v4()),
      title: Value(title.trim()),
      content: Value(content.trim()),
      noteType: Value(noteType),
      projectId: Value(projectId),
      meetingDate: Value(meetingDate),
      participants: Value(participants?.trim().isEmpty == true ? null : participants?.trim()),
      actionItems: Value(actionItems?.trim().isEmpty == true ? null : actionItems?.trim()),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await db.insertWorkNote(companion);
  }

  Future<void> updateWorkNote({
    required String id,
    required String title,
    required String content,
    required String noteType,
    String? projectId,
    DateTime? meetingDate,
    String? participants,
    String? actionItems,
  }) async {
    final companion = WorkNotesCompanion(
      id: Value(id),
      title: Value(title.trim()),
      content: Value(content.trim()),
      noteType: Value(noteType),
      projectId: Value(projectId),
      meetingDate: Value(meetingDate),
      participants: Value(participants?.trim().isEmpty == true ? null : participants?.trim()),
      actionItems: Value(actionItems?.trim().isEmpty == true ? null : actionItems?.trim()),
      updatedAt: Value(DateTime.now()),
    );
    await db.updateWorkNote(companion);
  }

  Future<void> deleteWorkNote(String id) => db.deleteWorkNote(id);
}

final workRepositoryProvider = Provider<WorkRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkRepository(db);
});
