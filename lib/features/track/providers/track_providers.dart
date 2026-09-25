import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../services/apas_dsa_service.dart';

// ==========================================
// 1. DSA PROVIDERS & MODELS
// ==========================================

enum DSASortOption {
  recentlyAdded('Recently Added'),
  recentlySolved('Recently Solved'),
  revisionDue('Revision Due Date'),
  difficulty('Difficulty (Hard -> Easy)'),
  title('Title (A-Z)');

  final String label;
  const DSASortOption(this.label);
}

final dsaProblemsStreamProvider = StreamProvider<List<DSAProblem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllDSAProblems();
});

final dsaProblemByIdProvider = StreamProvider.family<DSAProblem?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.dSAProblems)..where((p) => p.id.equals(id))).watchSingleOrNull();
});

final dsaSearchQueryProvider = StateProvider<String>((ref) => '');
final dsaTopicFilterProvider = StateProvider<String>((ref) => 'all');
final dsaDifficultyFilterProvider = StateProvider<String>((ref) => 'all');
final dsaStatusFilterProvider = StateProvider<String>((ref) => 'all');
final dsaSortOptionProvider = StateProvider<DSASortOption>((ref) => DSASortOption.recentlyAdded);

final filteredDSAProblemsProvider = Provider<List<DSAProblem>>((ref) {
  final problemsAsync = ref.watch(dsaProblemsStreamProvider);
  final query = ref.watch(dsaSearchQueryProvider).trim().toLowerCase();
  final topicFilter = ref.watch(dsaTopicFilterProvider);
  final diffFilter = ref.watch(dsaDifficultyFilterProvider);
  final statusFilter = ref.watch(dsaStatusFilterProvider);
  final sort = ref.watch(dsaSortOptionProvider);

  return problemsAsync.maybeWhen(
    data: (problems) {
      var list = List<DSAProblem>.from(problems);

      // Topic filter
      if (topicFilter != 'all') {
        list = list.where((p) => p.topic.toLowerCase() == topicFilter.toLowerCase()).toList();
      }

      // Difficulty filter
      if (diffFilter != 'all') {
        list = list.where((p) => p.difficulty.toUpperCase() == diffFilter.toUpperCase()).toList();
      }

      // Status filter
      if (statusFilter != 'all') {
        list = list.where((p) => p.status.toUpperCase() == statusFilter.toUpperCase()).toList();
      }

      // Search Query
      if (query.isNotEmpty) {
        list = list.where((p) {
          final title = p.title.toLowerCase();
          final topic = p.topic.toLowerCase();
          final platform = p.platform.toLowerCase();
          final notes = (p.notes ?? '').toLowerCase();
          final solution = (p.solution ?? '').toLowerCase();
          return title.contains(query) ||
              topic.contains(query) ||
              platform.contains(query) ||
              notes.contains(query) ||
              solution.contains(query);
        }).toList();
      }

      // Sorting
      switch (sort) {
        case DSASortOption.recentlyAdded:
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case DSASortOption.recentlySolved:
          list.sort((a, b) {
            if (a.solvedAt == null && b.solvedAt == null) return 0;
            if (a.solvedAt == null) return 1;
            if (b.solvedAt == null) return -1;
            return b.solvedAt!.compareTo(a.solvedAt!);
          });
          break;
        case DSASortOption.revisionDue:
          list.sort((a, b) {
            if (a.revisionDate == null && b.revisionDate == null) return 0;
            if (a.revisionDate == null) return 1;
            if (b.revisionDate == null) return -1;
            return a.revisionDate!.compareTo(b.revisionDate!);
          });
          break;
        case DSASortOption.difficulty:
          final weights = {'HARD': 3, 'MEDIUM': 2, 'EASY': 1};
          list.sort((a, b) {
            final wA = weights[a.difficulty.toUpperCase()] ?? 0;
            final wB = weights[b.difficulty.toUpperCase()] ?? 0;
            return wB.compareTo(wA);
          });
          break;
        case DSASortOption.title:
          list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          break;
      }

      return list;
    },
    orElse: () => [],
  );
});

// Revision Providers
final dsaRevisionProblemsProvider = Provider<List<DSAProblem>>((ref) {
  final problems = ref.watch(dsaProblemsStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return problems.where((p) {
    if (p.revisionDate == null) return false;
    return p.revisionDate!.isBefore(endOfToday) ||
        (p.revisionDate!.year == now.year &&
            p.revisionDate!.month == now.month &&
            p.revisionDate!.day == now.day);
  }).toList()
    ..sort((a, b) => a.revisionDate!.compareTo(b.revisionDate!));
});

class DSADashboardStats {
  final int total;
  final int solved;
  final int attempted;
  final int needsRevision;
  final int todo;
  final int revisionDue;
  final int overdueRevision;
  final Map<String, int> topicCounts;
  final Map<String, int> difficultyCounts;

  const DSADashboardStats({
    required this.total,
    required this.solved,
    required this.attempted,
    required this.needsRevision,
    required this.todo,
    required this.revisionDue,
    required this.overdueRevision,
    required this.topicCounts,
    required this.difficultyCounts,
  });
}

final dsaDashboardStatsProvider = Provider<DSADashboardStats>((ref) {
  final problems = ref.watch(dsaProblemsStreamProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

  int solved = 0;
  int attempted = 0;
  int needsRevision = 0;
  int todo = 0;
  int revisionDue = 0;
  int overdueRevision = 0;
  final Map<String, int> topicCounts = {};
  final Map<String, int> difficultyCounts = {'EASY': 0, 'MEDIUM': 0, 'HARD': 0};

  for (final p in problems) {
    final s = p.status.toUpperCase();
    if (s == 'SOLVED') {
      solved++;
    } else if (s == 'ATTEMPTED') {
      attempted++;
    } else if (s == 'NEEDS_REVISION') {
      needsRevision++;
    } else {
      todo++;
    }

    final diff = p.difficulty.toUpperCase();
    difficultyCounts[diff] = (difficultyCounts[diff] ?? 0) + 1;

    topicCounts[p.topic] = (topicCounts[p.topic] ?? 0) + 1;

    if (p.revisionDate != null) {
      if (p.revisionDate!.isBefore(startOfToday)) {
        overdueRevision++;
        revisionDue++;
      } else if (p.revisionDate!.isBefore(endOfToday)) {
        revisionDue++;
      }
    }
  }

  return DSADashboardStats(
    total: problems.length,
    solved: solved,
    attempted: attempted,
    needsRevision: needsRevision,
    todo: todo,
    revisionDue: revisionDue,
    overdueRevision: overdueRevision,
    topicCounts: topicCounts,
    difficultyCounts: difficultyCounts,
  );
});

// ==========================================
// 2. LEARNING & RESOURCES PROVIDERS
// ==========================================

final skillsStreamProvider = StreamProvider<List<LearningSkill>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSkills();
});

final skillByIdProvider = StreamProvider.family<LearningSkill?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.learningSkills)..where((s) => s.id.equals(id))).watchSingleOrNull();
});

final resourcesStreamProvider = StreamProvider<List<Resource>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllResources();
});

final resourcesBySkillProvider = StreamProvider.family<List<Resource>, String>((ref, skillId) {
  final db = ref.watch(databaseProvider);
  return db.watchResourcesBySkillId(skillId);
});

final resourceSearchQueryProvider = StateProvider<String>((ref) => '');
final resourceTypeFilterProvider = StateProvider<String>((ref) => 'all');
final resourceStatusFilterProvider = StateProvider<String>((ref) => 'all');

final filteredResourcesProvider = Provider<List<Resource>>((ref) {
  final resAsync = ref.watch(resourcesStreamProvider);
  final query = ref.watch(resourceSearchQueryProvider).trim().toLowerCase();
  final typeFilter = ref.watch(resourceTypeFilterProvider);
  final statusFilter = ref.watch(resourceStatusFilterProvider);

  return resAsync.maybeWhen(
    data: (resources) {
      var list = List<Resource>.from(resources);

      if (typeFilter != 'all') {
        list = list.where((r) => r.type.toUpperCase() == typeFilter.toUpperCase()).toList();
      }

      if (statusFilter != 'all') {
        list = list.where((r) => r.status.toUpperCase() == statusFilter.toUpperCase()).toList();
      }

      if (query.isNotEmpty) {
        list = list.where((r) {
          final title = r.title.toLowerCase();
          final category = (r.category ?? '').toLowerCase();
          final tags = (r.tags ?? '').toLowerCase();
          final notes = (r.notes ?? '').toLowerCase();
          return title.contains(query) || category.contains(query) || tags.contains(query) || notes.contains(query);
        }).toList();
      }

      return list;
    },
    orElse: () => [],
  );
});

// ==========================================
// 3. FITNESS PROVIDERS & MODELS
// ==========================================

final bodyWeightsStreamProvider = StreamProvider<List<BodyWeight>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllBodyWeights();
});

final latestBodyWeightProvider = Provider<BodyWeight?>((ref) {
  final weights = ref.watch(bodyWeightsStreamProvider).valueOrNull ?? [];
  return weights.isNotEmpty ? weights.first : null;
});

final workoutsStreamProvider = StreamProvider<List<Workout>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllWorkouts();
});

final workoutByIdProvider = StreamProvider.family<Workout?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.workouts)..where((w) => w.id.equals(id))).watchSingleOrNull();
});

final workoutExercisesStreamProvider = StreamProvider.family<List<WorkoutExercise>, String>((ref, workoutId) {
  final db = ref.watch(databaseProvider);
  return db.watchExercisesForWorkout(workoutId);
});

final workoutTemplatesStreamProvider = StreamProvider<List<WorkoutTemplate>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllWorkoutTemplates();
});

// ==========================================
// 4. FINANCE PROVIDERS & MODELS
// ==========================================

enum FinanceSortOption {
  newest('Newest First'),
  oldest('Oldest First'),
  amountHighest('Amount (Highest First)'),
  amountLowest('Amount (Lowest First)');

  final String label;
  const FinanceSortOption(this.label);
}

final incomesStreamProvider = StreamProvider<List<Income>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllIncomes();
});

final expensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllExpenses();
});

final financeSelectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final expenseCategoryFilterProvider = StateProvider<String>((ref) => 'all');
final financeSearchQueryProvider = StateProvider<String>((ref) => '');
final financeSortOptionProvider = StateProvider<FinanceSortOption>((ref) => FinanceSortOption.newest);

final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final expensesAsync = ref.watch(expensesStreamProvider);
  final selectedDate = ref.watch(financeSelectedDateProvider);
  final categoryFilter = ref.watch(expenseCategoryFilterProvider);
  final query = ref.watch(financeSearchQueryProvider).trim().toLowerCase();
  final sort = ref.watch(financeSortOptionProvider);

  return expensesAsync.maybeWhen(
    data: (expenses) {
      var list = expenses.where((e) {
        return e.date.year == selectedDate.year && e.date.month == selectedDate.month;
      }).toList();

      if (categoryFilter != 'all') {
        list = list.where((e) => e.category.toLowerCase() == categoryFilter.toLowerCase()).toList();
      }

      if (query.isNotEmpty) {
        list = list.where((e) {
          final desc = e.description.toLowerCase();
          final cat = e.category.toLowerCase();
          final notes = (e.notes ?? '').toLowerCase();
          return desc.contains(query) || cat.contains(query) || notes.contains(query);
        }).toList();
      }

      switch (sort) {
        case FinanceSortOption.newest:
          list.sort((a, b) => b.date.compareTo(a.date));
          break;
        case FinanceSortOption.oldest:
          list.sort((a, b) => a.date.compareTo(b.date));
          break;
        case FinanceSortOption.amountHighest:
          list.sort((a, b) => b.amount.compareTo(a.amount));
          break;
        case FinanceSortOption.amountLowest:
          list.sort((a, b) => a.amount.compareTo(b.amount));
          break;
      }

      return list;
    },
    orElse: () => [],
  );
});

final filteredIncomesProvider = Provider<List<Income>>((ref) {
  final incomesAsync = ref.watch(incomesStreamProvider);
  final selectedDate = ref.watch(financeSelectedDateProvider);
  final query = ref.watch(financeSearchQueryProvider).trim().toLowerCase();
  final sort = ref.watch(financeSortOptionProvider);

  return incomesAsync.maybeWhen(
    data: (incomes) {
      var list = incomes.where((i) {
        return i.date.year == selectedDate.year && i.date.month == selectedDate.month;
      }).toList();

      if (query.isNotEmpty) {
        list = list.where((i) {
          final src = i.source.toLowerCase();
          final cat = i.category.toLowerCase();
          final notes = (i.notes ?? '').toLowerCase();
          return src.contains(query) || cat.contains(query) || notes.contains(query);
        }).toList();
      }

      switch (sort) {
        case FinanceSortOption.newest:
          list.sort((a, b) => b.date.compareTo(a.date));
          break;
        case FinanceSortOption.oldest:
          list.sort((a, b) => a.date.compareTo(b.date));
          break;
        case FinanceSortOption.amountHighest:
          list.sort((a, b) => b.amount.compareTo(a.amount));
          break;
        case FinanceSortOption.amountLowest:
          list.sort((a, b) => a.amount.compareTo(b.amount));
          break;
      }

      return list;
    },
    orElse: () => [],
  );
});

class FinanceSummary {
  final double monthIncome;
  final double monthExpenses;
  final double netSavings;
  final Map<String, double> categoryBreakdown;

  const FinanceSummary({
    required this.monthIncome,
    required this.monthExpenses,
    required this.netSavings,
    required this.categoryBreakdown,
  });
}

final financeSummaryProvider = Provider<FinanceSummary>((ref) {
  final expenses = ref.watch(expensesStreamProvider).valueOrNull ?? [];
  final incomes = ref.watch(incomesStreamProvider).valueOrNull ?? [];
  final selectedDate = ref.watch(financeSelectedDateProvider);

  double monthIncome = 0.0;
  double monthExpenses = 0.0;
  final Map<String, double> categoryBreakdown = {};

  for (final i in incomes) {
    if (i.date.year == selectedDate.year && i.date.month == selectedDate.month) {
      monthIncome += i.amount;
    }
  }

  for (final e in expenses) {
    if (e.date.year == selectedDate.year && e.date.month == selectedDate.month) {
      monthExpenses += e.amount;
      categoryBreakdown[e.category] = (categoryBreakdown[e.category] ?? 0.0) + e.amount;
    }
  }

  return FinanceSummary(
    monthIncome: monthIncome,
    monthExpenses: monthExpenses,
    netSavings: monthIncome - monthExpenses,
    categoryBreakdown: categoryBreakdown,
  );
});

// ==========================================
// 5. OVERALL TRACK SNAPSHOT
// ==========================================

class TrackSnapshot {
  final int dsaSolved;
  final int dsaRevisionDue;
  final int activeSkillsCount;
  final int learningResourcesCount;
  final double? latestWeight;
  final DateTime? latestWeightDate;
  final String? recentWorkoutName;
  final DateTime? recentWorkoutDate;
  final double currentMonthIncome;
  final double currentMonthExpenses;
  final double currentMonthSavings;

  const TrackSnapshot({
    required this.dsaSolved,
    required this.dsaRevisionDue,
    required this.activeSkillsCount,
    required this.learningResourcesCount,
    this.latestWeight,
    this.latestWeightDate,
    this.recentWorkoutName,
    this.recentWorkoutDate,
    required this.currentMonthIncome,
    required this.currentMonthExpenses,
    required this.currentMonthSavings,
  });
}

final trackSnapshotProvider = Provider<TrackSnapshot>((ref) {
  final dsaStats = ref.watch(dsaDashboardStatsProvider);
  final skills = ref.watch(skillsStreamProvider).valueOrNull ?? [];
  final resources = ref.watch(resourcesStreamProvider).valueOrNull ?? [];
  final latestWeight = ref.watch(latestBodyWeightProvider);
  final workouts = ref.watch(workoutsStreamProvider).valueOrNull ?? [];
  final financeSummary = ref.watch(financeSummaryProvider);

  final learningResources = resources.where((r) => r.status.toUpperCase() == 'LEARNING').length;
  final recentWorkout = workouts.isNotEmpty ? workouts.first : null;

  return TrackSnapshot(
    dsaSolved: dsaStats.solved,
    dsaRevisionDue: dsaStats.revisionDue,
    activeSkillsCount: skills.length,
    learningResourcesCount: learningResources,
    latestWeight: latestWeight?.weight,
    latestWeightDate: latestWeight?.date,
    recentWorkoutName: recentWorkout?.name,
    recentWorkoutDate: recentWorkout?.date,
    currentMonthIncome: financeSummary.monthIncome,
    currentMonthExpenses: financeSummary.monthExpenses,
    currentMonthSavings: financeSummary.netSavings,
  );
});

// ==========================================
// 6. TRACK REPOSITORY (BUSINESS LOGIC)
// ==========================================

class TrackRepository {
  final AppDatabase db;
  static const _uuid = Uuid();

  TrackRepository(this.db);

  // --- DSA Methods ---
  Future<void> addDSAProblem({
    required String title,
    String platform = 'LeetCode',
    String? url,
    String topic = 'Arrays',
    DSADifficulty difficulty = DSADifficulty.medium,
    DSAStatus status = DSAStatus.todo,
    String? solution,
    String? notes,
    DateTime? revisionDate,
  }) async {
    final now = DateTime.now();
    final companion = DSAProblemsCompanion(
      id: drift.Value(_uuid.v4()),
      title: drift.Value(title.trim()),
      platform: drift.Value(platform.trim()),
      url: drift.Value(url?.trim().isEmpty == true ? null : url?.trim()),
      topic: drift.Value(topic.trim()),
      difficulty: drift.Value(difficulty.value),
      status: drift.Value(status.value),
      attempts: drift.Value(status == DSAStatus.solved || status == DSAStatus.attempted ? 1 : 0),
      attemptedAt: drift.Value(status != DSAStatus.todo ? now : null),
      solvedAt: drift.Value(status == DSAStatus.solved ? now : null),
      solution: drift.Value(solution?.trim().isEmpty == true ? null : solution?.trim()),
      notes: drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      revisionDate: drift.Value(revisionDate),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );
    await db.insertDSAProblem(companion);
  }

  Future<void> updateDSAProblem({
    required String id,
    required String title,
    required String platform,
    String? url,
    required String topic,
    required DSADifficulty difficulty,
    required DSAStatus status,
    int? attempts,
    String? solution,
    String? notes,
    DateTime? revisionDate,
    DateTime? solvedAt,
  }) async {
    final companion = DSAProblemsCompanion(
      id: drift.Value(id),
      title: drift.Value(title.trim()),
      platform: drift.Value(platform.trim()),
      url: drift.Value(url?.trim().isEmpty == true ? null : url?.trim()),
      topic: drift.Value(topic.trim()),
      difficulty: drift.Value(difficulty.value),
      status: drift.Value(status.value),
      attempts: attempts != null ? drift.Value(attempts) : const drift.Value.absent(),
      solvedAt: drift.Value(status == DSAStatus.solved ? (solvedAt ?? DateTime.now()) : null),
      solution: drift.Value(solution?.trim().isEmpty == true ? null : solution?.trim()),
      notes: drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      revisionDate: drift.Value(revisionDate),
      updatedAt: drift.Value(DateTime.now()),
    );
    await db.updateDSAProblem(companion);
  }

  Future<void> recordDSAAttempt(DSAProblem problem, {bool solved = false}) async {
    final now = DateTime.now();
    final newAttempts = problem.attempts + 1;
    final newStatus = solved ? 'SOLVED' : 'ATTEMPTED';

    final companion = DSAProblemsCompanion(
      id: drift.Value(problem.id),
      title: drift.Value(problem.title),
      platform: drift.Value(problem.platform),
      url: drift.Value(problem.url),
      topic: drift.Value(problem.topic),
      difficulty: drift.Value(problem.difficulty),
      status: drift.Value(newStatus),
      attempts: drift.Value(newAttempts),
      attemptedAt: drift.Value(now),
      solvedAt: drift.Value(solved ? now : problem.solvedAt),
      solution: drift.Value(problem.solution),
      notes: drift.Value(problem.notes),
      revisionDate: drift.Value(problem.revisionDate),
      createdAt: drift.Value(problem.createdAt),
      updatedAt: drift.Value(now),
    );
    await db.updateDSAProblem(companion);
  }

  Future<void> updateDSAStatus(String id, DSAStatus status) => db.updateDSAStatus(id, status.value);
  Future<void> setDSARevisionDate(String id, DateTime? date) => db.updateDSARevisionDate(id, date);
  Future<void> deleteDSAProblem(String id) => db.deleteDSAProblem(id);

  // --- Learning Skills Methods ---
  Future<void> addSkill({
    required String name,
    String category = 'Technical',
    SkillLevel currentLevel = SkillLevel.beginner,
    SkillLevel targetLevel = SkillLevel.advanced,
    String? notes,
  }) async {
    final now = DateTime.now();
    final companion = LearningSkillsCompanion(
      id: drift.Value(_uuid.v4()),
      name: drift.Value(name.trim()),
      category: drift.Value(category.trim()),
      currentLevel: drift.Value(currentLevel.value),
      targetLevel: drift.Value(targetLevel.value),
      notes: drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );
    await db.insertSkill(companion);
  }

  Future<void> updateSkill({
    required String id,
    required String name,
    required String category,
    required SkillLevel currentLevel,
    required SkillLevel targetLevel,
    String? notes,
  }) async {
    final companion = LearningSkillsCompanion(
      id: drift.Value(id),
      name: drift.Value(name.trim()),
      category: drift.Value(category.trim()),
      currentLevel: drift.Value(currentLevel.value),
      targetLevel: drift.Value(targetLevel.value),
      notes: drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      updatedAt: drift.Value(DateTime.now()),
    );
    await db.updateSkill(companion);
  }

  Future<void> deleteSkill(String id) => db.deleteSkill(id);

  // --- Resource Methods ---
  Future<void> addResource({
    required String title,
    String? url,
    ResourceType type = ResourceType.documentation,
    String? category,
    String? tags,
    ResourceStatus status = ResourceStatus.toRead,
    String? notes,
    String? skillId,
  }) async {
    final now = DateTime.now();
    final companion = ResourcesCompanion(
      id: drift.Value(_uuid.v4()),
      title: drift.Value(title.trim()),
      url: drift.Value(url?.trim().isEmpty == true ? null : url?.trim()),
      type: drift.Value(type.value),
      category: drift.Value(category?.trim().isEmpty == true ? null : category?.trim()),
      tags: drift.Value(tags?.trim().isEmpty == true ? null : tags?.trim()),
      status: drift.Value(status.value),
      notes: drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      skillId: drift.Value(skillId),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );
    await db.insertResource(companion);
  }

  Future<void> updateResource({
    required String id,
    required String title,
    String? url,
    required ResourceType type,
    String? category,
    String? tags,
    required ResourceStatus status,
    String? notes,
    String? skillId,
  }) async {
    final companion = ResourcesCompanion(
      id: drift.Value(id),
      title: drift.Value(title.trim()),
      url: drift.Value(url?.trim().isEmpty == true ? null : url?.trim()),
      type: drift.Value(type.value),
      category: drift.Value(category?.trim().isEmpty == true ? null : category?.trim()),
      tags: drift.Value(tags?.trim().isEmpty == true ? null : tags?.trim()),
      status: drift.Value(status.value),
      notes: drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      skillId: drift.Value(skillId),
      updatedAt: drift.Value(DateTime.now()),
    );
    await db.updateResource(companion);
  }

  Future<void> updateResourceStatus(String id, ResourceStatus status) =>
      db.updateResourceStatus(id, status.value);
  Future<void> deleteResource(String id) => db.deleteResource(id);

  // --- Fitness Body Weight Methods ---
  Future<void> logWeight({
    required double weight,
    DateTime? date,
    String? note,
  }) async {
    final companion = BodyWeightsCompanion(
      id: drift.Value(_uuid.v4()),
      date: drift.Value(date ?? DateTime.now()),
      weight: drift.Value(weight),
      note: drift.Value(note?.trim().isEmpty == true ? null : note?.trim()),
      createdAt: drift.Value(DateTime.now()),
    );
    await db.insertBodyWeight(companion);
  }

  Future<void> deleteWeight(String id) => db.deleteBodyWeight(id);

  // --- Fitness Workout & Exercises Methods ---
  Future<String> logWorkout({
    required String name,
    DateTime? date,
    int? duration,
    String? notes,
    List<WorkoutExercisesCompanion> exercises = const [],
  }) async {
    final now = DateTime.now();
    final workoutId = _uuid.v4();

    final workoutComp = WorkoutsCompanion(
      id: drift.Value(workoutId),
      name: drift.Value(name.trim()),
      date: drift.Value(date ?? now),
      duration: drift.Value(duration),
      notes: drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );

    await db.insertWorkout(workoutComp);

    for (final ex in exercises) {
      final exComp = WorkoutExercisesCompanion(
        id: drift.Value(_uuid.v4()),
        workoutId: drift.Value(workoutId),
        exerciseName: drift.Value(ex.exerciseName.value.trim()),
        sets: drift.Value(ex.sets.value),
        reps: drift.Value(ex.reps.value),
        weight: drift.Value(ex.weight.value),
        notes: drift.Value(ex.notes.value),
      );
      await db.insertWorkoutExercise(exComp);
    }

    return workoutId;
  }

  Future<void> updateWorkout({
    required String id,
    required String name,
    required DateTime date,
    int? duration,
    String? notes,
    List<WorkoutExercisesCompanion> exercises = const [],
  }) async {
    final workoutComp = WorkoutsCompanion(
      id: drift.Value(id),
      name: drift.Value(name.trim()),
      date: drift.Value(date),
      duration: drift.Value(duration),
      notes: drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      updatedAt: drift.Value(DateTime.now()),
    );

    await db.updateWorkout(workoutComp);

    // Replace exercises
    await db.deleteExercisesForWorkout(id);
    for (final ex in exercises) {
      final exComp = WorkoutExercisesCompanion(
        id: drift.Value(_uuid.v4()),
        workoutId: drift.Value(id),
        exerciseName: drift.Value(ex.exerciseName.value.trim()),
        sets: drift.Value(ex.sets.value),
        reps: drift.Value(ex.reps.value),
        weight: drift.Value(ex.weight.value),
        notes: drift.Value(ex.notes.value),
      );
      await db.insertWorkoutExercise(exComp);
    }
  }

  Future<void> deleteWorkout(String id) => db.deleteWorkout(id);

  Future<void> addWorkoutTemplate({
    required String name,
    String? notes,
  }) async {
    final now = DateTime.now();
    final companion = WorkoutTemplatesCompanion(
      id: drift.Value(_uuid.v4()),
      name: drift.Value(name.trim()),
      notes: drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );
    await db.insertWorkoutTemplate(companion);
  }

  Future<void> deleteWorkoutTemplate(String id) => db.deleteWorkoutTemplate(id);

  // --- Finance Income & Expense Methods ---
  Future<void> addIncome({
    required double amount,
    required String source,
    DateTime? date,
    String category = 'Salary',
    String? notes,
  }) async {
    final now = DateTime.now();
    final companion = IncomesCompanion(
      id: drift.Value(_uuid.v4()),
      amount: drift.Value(amount),
      date: drift.Value(date ?? now),
      source: drift.Value(source.trim()),
      category: drift.Value(category.trim()),
      notes: drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );
    await db.insertIncome(companion);
  }

  Future<void> updateIncome({
    required String id,
    required double amount,
    required String source,
    required DateTime date,
    required String category,
    String? notes,
  }) async {
    final companion = IncomesCompanion(
      id: drift.Value(id),
      amount: drift.Value(amount),
      date: drift.Value(date),
      source: drift.Value(source.trim()),
      category: drift.Value(category.trim()),
      notes: drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      updatedAt: drift.Value(DateTime.now()),
    );
    await db.updateIncome(companion);
  }

  Future<void> deleteIncome(String id) => db.deleteIncome(id);

  Future<void> addExpense({
    required double amount,
    required String description,
    DateTime? date,
    String category = 'Food & Dining',
    String? notes,
  }) async {
    final now = DateTime.now();
    final companion = ExpensesCompanion(
      id: drift.Value(_uuid.v4()),
      amount: drift.Value(amount),
      date: drift.Value(date ?? now),
      description: drift.Value(description.trim()),
      category: drift.Value(category.trim()),
      notes: drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
    );
    await db.insertExpense(companion);
  }

  Future<void> updateExpense({
    required String id,
    required double amount,
    required String description,
    required DateTime date,
    required String category,
    String? notes,
  }) async {
    final companion = ExpensesCompanion(
      id: drift.Value(id),
      amount: drift.Value(amount),
      date: drift.Value(date),
      description: drift.Value(description.trim()),
      category: drift.Value(category.trim()),
      notes: drift.Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      updatedAt: drift.Value(DateTime.now()),
    );
    await db.updateExpense(companion);
  }

  Future<void> deleteExpense(String id) => db.deleteExpense(id);

  // --- CSV Export Generation (RFC 4180 Compliant) ---
  String generateFinanceCsv({
    required List<Income> incomes,
    required List<Expense> expenses,
  }) {
    final buffer = StringBuffer();

    // Escape helper
    String escape(String value) {
      if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
        return '"${value.replaceAll('"', '""')}"';
      }
      return value;
    }

    // Header
    buffer.writeln('Type,Date,Category,Source / Description,Amount,Notes');

    // Incomes
    for (final inc in incomes) {
      final dateStr = '${inc.date.year}-${inc.date.month.toString().padLeft(2, '0')}-${inc.date.day.toString().padLeft(2, '0')}';
      buffer.writeln(
        'INCOME,${escape(dateStr)},${escape(inc.category)},${escape(inc.source)},${inc.amount.toStringAsFixed(2)},${escape(inc.notes ?? '')}',
      );
    }

    // Expenses
    for (final exp in expenses) {
      final dateStr = '${exp.date.year}-${exp.date.month.toString().padLeft(2, '0')}-${exp.date.day.toString().padLeft(2, '0')}';
      buffer.writeln(
        'EXPENSE,${escape(dateStr)},${escape(exp.category)},${escape(exp.description)},${exp.amount.toStringAsFixed(2)},${escape(exp.notes ?? '')}',
      );
    }

    return buffer.toString();
  }
}

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TrackRepository(db);
});

final apasDsaServiceProvider = Provider<ApasDsaService>((ref) {
  final db = ref.watch(databaseProvider);
  return ApasDsaService(db: db);
});
