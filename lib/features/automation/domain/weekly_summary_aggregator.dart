import '../../../core/database/app_database.dart';
import 'automation_models.dart';

class WeeklySummaryAggregator {
  final AppDatabase db;

  WeeklySummaryAggregator(this.db);

  Future<WeeklySummaryData> aggregate({DateTime? forDate}) async {
    final now = forDate ?? DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));
    final weekEnd = now;

    // 1. Career
    final allJobs = await db.getAllJobs();
    final jobsDiscovered = allJobs.where((j) => j.createdAt.isAfter(weekStart)).length;

    final allApps = await db.getAllApplications();
    final applicationsSubmitted = allApps.where((a) => a.appliedAt != null && a.appliedAt!.isAfter(weekStart)).length;
    final followUpsCompleted = allApps.where((a) => a.status != 'applied' && a.updatedAt.isAfter(weekStart)).length;

    // 2. Work & Tasks
    final allTasks = await db.getAllTasks();
    final tasksCompleted = allTasks.where((t) => t.status == 'completed' && t.updatedAt.isAfter(weekStart)).length;
    final tasksPending = allTasks.where((t) => t.status != 'completed').length;

    final allEODs = await db.getAllEODNotes();
    final eodNotesLogged = allEODs.where((e) => e.date.isAfter(weekStart)).length;

    // 3. DSA & Learning
    final allDsa = await db.getAllDSAProblems();
    final dsaProblemsSolved = allDsa.where((d) => d.status.toUpperCase() == 'SOLVED' && d.solvedAt != null && d.solvedAt!.isAfter(weekStart)).length;
    final dsaProblemsAttempted = allDsa.fold<int>(0, (sum, d) => sum + d.attempts);

    final allSkills = await db.getAllSkills();
    final skillsPracticed = allSkills.where((s) => s.updatedAt.isAfter(weekStart)).length;

    // 4. Fitness
    final allWorkouts = await db.getAllWorkouts();
    final workoutsLogged = allWorkouts.where((w) => w.date.isAfter(weekStart)).length;

    // 5. Finance
    final allIncomes = await db.getAllIncomes();
    final totalIncome = allIncomes
        .where((i) => i.date.isAfter(weekStart))
        .fold<double>(0.0, (sum, i) => sum + i.amount);

    final allExpenses = await db.getAllExpenses();
    final totalExpense = allExpenses
        .where((e) => e.date.isAfter(weekStart))
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    final netSavings = totalIncome - totalExpense;

    // 6. Freelance
    final allLeads = await db.getAllFreelanceLeads();
    final freelanceLeadsCreated = allLeads.where((l) => l.createdAt.isAfter(weekStart)).length;

    final allPayments = await db.getAllFreelancePayments();
    final freelanceMilestonesPaid = allPayments.where((p) => p.status.toUpperCase() == 'PAID' && p.paymentDate.isAfter(weekStart)).length;

    return WeeklySummaryData(
      weekStart: weekStart,
      weekEnd: weekEnd,
      jobsDiscovered: jobsDiscovered,
      applicationsSubmitted: applicationsSubmitted,
      followUpsCompleted: followUpsCompleted,
      tasksCompleted: tasksCompleted,
      tasksPending: tasksPending,
      eodNotesLogged: eodNotesLogged,
      dsaProblemsSolved: dsaProblemsSolved,
      dsaProblemsAttempted: dsaProblemsAttempted,
      skillsPracticed: skillsPracticed,
      workoutsLogged: workoutsLogged,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netSavings: netSavings,
      freelanceLeadsCreated: freelanceLeadsCreated,
      freelanceMilestonesPaid: freelanceMilestonesPaid,
    );
  }
}
