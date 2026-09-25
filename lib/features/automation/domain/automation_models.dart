import 'dart:convert';

enum AutomationType {
  jobSearch,
  jobMatching,
  applicationFollowup,
  workDeadline,
  eodReminder,
  dsaRevision,
  freelanceFollowup,
  projectDeadline,
  weeklySummary,
}

enum AutomationSchedule {
  hourly,
  dailyMorning,
  dailyEvening,
  weekly,
  manual,
}

enum NotificationCategory {
  career,
  work,
  dsa,
  freelance,
  projects,
  weeklySummary,
}

class RawJobItem {
  final String title;
  final String company;
  final String? location;
  final String? skills;
  final String? url;
  final String? description;
  final String? salary;
  final bool isRemote;
  final DateTime? publishedAt;

  const RawJobItem({
    required this.title,
    required this.company,
    this.location,
    this.skills,
    this.url,
    this.description,
    this.salary,
    this.isRemote = false,
    this.publishedAt,
  });
}

class DeduplicationResult {
  final bool isDuplicate;
  final String? reason;
  final String? matchedJobId;

  const DeduplicationResult({
    required this.isDuplicate,
    this.reason,
    this.matchedJobId,
  });
}

class ActionProposalItem {
  final String actionType;
  final String title;
  final String description;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? payload;
  final String urgency; // 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'

  const ActionProposalItem({
    required this.actionType,
    required this.title,
    required this.description,
    required this.entityType,
    this.entityId,
    this.payload,
    this.urgency = 'MEDIUM',
  });

  String get payloadJson => payload != null ? jsonEncode(payload) : '';
}

class RuleEvaluationResult {
  final String ruleId;
  final bool isSuccess;
  final int itemsEvaluated;
  final int itemsCreated;
  final List<String> messages;
  final List<ActionProposalItem> proposedActions;

  const RuleEvaluationResult({
    required this.ruleId,
    required this.isSuccess,
    this.itemsEvaluated = 0,
    this.itemsCreated = 0,
    this.messages = const [],
    this.proposedActions = const [],
  });
}

class WeeklySummaryData {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int jobsDiscovered;
  final int applicationsSubmitted;
  final int followUpsCompleted;
  final int tasksCompleted;
  final int tasksPending;
  final int eodNotesLogged;
  final int dsaProblemsSolved;
  final int dsaProblemsAttempted;
  final int skillsPracticed;
  final int workoutsLogged;
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final int freelanceLeadsCreated;
  final int freelanceMilestonesPaid;

  const WeeklySummaryData({
    required this.weekStart,
    required this.weekEnd,
    required this.jobsDiscovered,
    required this.applicationsSubmitted,
    required this.followUpsCompleted,
    required this.tasksCompleted,
    required this.tasksPending,
    required this.eodNotesLogged,
    required this.dsaProblemsSolved,
    required this.dsaProblemsAttempted,
    required this.skillsPracticed,
    required this.workoutsLogged,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.freelanceLeadsCreated,
    required this.freelanceMilestonesPaid,
  });

  String toMarkdownReport() {
    final startStr = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    final endStr = '${weekEnd.year}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}';

    return '''
# 📊 Weekly Career OS Summary
**Period:** $startStr to $endStr

### 🎯 Career & Applications
- Jobs Discovered: **$jobsDiscovered**
- Applications Submitted: **$applicationsSubmitted**
- Follow-ups Addressed: **$followUpsCompleted**

### 💼 Work & Tasks
- Completed Tasks: **$tasksCompleted**
- Tasks In Progress / Pending: **$tasksPending**
- Daily EOD Standups Logged: **$eodNotesLogged**

### 🧠 DSA & Learning
- DSA Problems Solved: **$dsaProblemsSolved**
- Total DSA Attempts: **$dsaProblemsAttempted**
- Skills Practiced: **$skillsPracticed**

### 🤝 Freelance
- New Leads Tracked: **$freelanceLeadsCreated**
- Milestones Paid: **$freelanceMilestonesPaid**

### 🏃 Fitness & 💰 Finance
- Workouts Completed: **$workoutsLogged**
- Total Income: **\$${totalIncome.toStringAsFixed(2)}**
- Total Expenses: **\$${totalExpense.toStringAsFixed(2)}**
- Net Savings: **\$${netSavings.toStringAsFixed(2)}**
''';
  }
}
