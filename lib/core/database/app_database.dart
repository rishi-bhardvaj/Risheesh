import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

// 1. User Profiles Table
class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get currentRole => text().nullable()();
  RealColumn get experienceYears => real().withDefault(const Constant(0.0))();
  TextColumn get skills => text().nullable()();
  TextColumn get programmingLanguages => text().nullable()();
  TextColumn get frameworks => text().nullable()();
  TextColumn get preferredRoles => text().nullable()();
  TextColumn get preferredLocations => text().nullable()();
  TextColumn get remotePreference => text().withDefault(const Constant('any'))();
  TextColumn get expectedSalary => text().nullable()();
  TextColumn get preferredEmploymentType => text().nullable()();
  TextColumn get noticePeriod => text().nullable()();
  TextColumn get education => text().nullable()();
  TextColumn get resumePreferences => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 2. Projects Table (Phase 1 + Phase 3 + Phase 4 Freelance extension)
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('in_progress'))(); // idea, planned, in_progress, paused, completed, archived
  RealColumn get progress => real().withDefault(const Constant(0.0))(); // 0.0 to 1.0
  TextColumn get techStack => text().nullable()();
  TextColumn get githubUrl => text().nullable()();
  TextColumn get liveUrl => text().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get clientId => text().nullable().references(Clients, #id, onDelete: KeyAction.setNull)();
  TextColumn get leadId => text().nullable().references(FreelanceLeads, #id, onDelete: KeyAction.setNull)();
  BoolColumn get isFreelance => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 3. Tasks Table
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 250)();
  TextColumn get description => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))(); // 'low', 'medium', 'high'
  TextColumn get status => text().withDefault(const Constant('todo'))(); // 'todo', 'in_progress', 'completed'
  TextColumn get category => text().withDefault(const Constant('work'))(); // 'work', 'personal'
  TextColumn get projectId => text().nullable().references(Projects, #id, onDelete: KeyAction.setNull)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 4. Resumes Table (Phase 2)
class Resumes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get version => text().withDefault(const Constant('v1.0'))();
  TextColumn get targetRole => text().nullable()();
  TextColumn get filePath => text()();
  TextColumn get fileName => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 5. Jobs Table
class Jobs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get company => text().withLength(min: 1, max: 150)();
  TextColumn get location => text().nullable()();
  TextColumn get salary => text().nullable()();
  TextColumn get employmentType => text().nullable()(); // Full-time, Remote, Contract, etc.
  TextColumn get experienceRequirement => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get source => text().nullable()(); // Manual, LinkedIn, Indeed, etc.
  TextColumn get description => text().nullable()();
  TextColumn get skills => text().nullable()();
  DateTimeColumn get postedDate => dateTime().nullable()();
  DateTimeColumn get discoveredAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSaved => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 6. Job Applications Table
class JobApplications extends Table {
  TextColumn get id => text()();
  TextColumn get jobId => text().nullable().references(Jobs, #id, onDelete: KeyAction.setNull)();
  TextColumn get company => text().withLength(min: 1, max: 150)();
  TextColumn get role => text().withLength(min: 1, max: 200)();
  TextColumn get salary => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('applied'))();
  DateTimeColumn get appliedAt => dateTime().nullable()();
  DateTimeColumn get followUpDate => dateTime().nullable()();
  DateTimeColumn get interviewDate => dateTime().nullable()();
  TextColumn get interviewStage => text().nullable()();
  TextColumn get recruiterName => text().nullable()();
  TextColumn get recruiterContact => text().nullable()();
  TextColumn get resumeId => text().nullable().references(Resumes, #id, onDelete: KeyAction.setNull)();
  TextColumn get resumeUsed => text().nullable()();
  TextColumn get coverLetterReference => text().nullable()();
  TextColumn get nextAction => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 7. Saved Searches Table (Phase 2)
@DataClassName('SavedSearch')
class SavedSearches extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get keywords => text().nullable()();
  TextColumn get jobTitle => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get remotePreference => text().nullable()();
  TextColumn get employmentType => text().nullable()();
  TextColumn get experience => text().nullable()();
  TextColumn get salary => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 8. EOD Notes Table (Phase 3)
class EODNotes extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get completedWork => text()();
  TextColumn get inProgressWork => text()();
  TextColumn get blockers => text().nullable()();
  TextColumn get tomorrowPlan => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 9. Things to Ask Table (Phase 3)
class ThingsToAsks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get status => text().withDefault(const Constant('open'))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 10. Work Notes Table (Phase 3)
class WorkNotes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get content => text()();
  TextColumn get noteType => text().withDefault(const Constant('scratchpad'))();
  TextColumn get projectId => text().nullable().references(Projects, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get meetingDate => dateTime().nullable()();
  TextColumn get participants => text().nullable()();
  TextColumn get actionItems => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 11. Clients Table (Phase 4 Freelance CRM)
class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get contactName => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get platform => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('PROSPECT'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 12. FreelanceLeads Table (Phase 4 Freelance Opportunity Pipeline)
class FreelanceLeads extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text().nullable().references(Clients, #id, onDelete: KeyAction.setNull)();
  TextColumn get projectId => text().nullable().references(Projects, #id, onDelete: KeyAction.setNull)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get clientName => text().nullable()();
  TextColumn get contactName => text().nullable()();
  TextColumn get contactInfo => text().nullable()();
  TextColumn get platform => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get skills => text().nullable()();
  RealColumn get budget => real().nullable()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  TextColumn get url => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('NEW_LEAD'))();
  TextColumn get proposal => text().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();
  DateTimeColumn get followUpDate => dateTime().nullable()();
  TextColumn get followUpNote => text().nullable()();
  TextColumn get nextAction => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get leadDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 13. FreelancePayments Table (Phase 4 Revenue & Payment Tracking)
class FreelancePayments extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text().references(Clients, #id, onDelete: KeyAction.cascade)();
  TextColumn get projectId => text().nullable().references(Projects, #id, onDelete: KeyAction.setNull)();
  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();
  DateTimeColumn get paymentDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('EXPECTED'))();
  TextColumn get description => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 14. DSAProblems Table (Phase 5 DSA Problem Tracker)
@DataClassName('DSAProblem')
class DSAProblems extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get platform => text().withDefault(const Constant('LeetCode'))();
  TextColumn get url => text().nullable()();
  TextColumn get topic => text().withDefault(const Constant('Arrays'))();
  TextColumn get difficulty => text().withDefault(const Constant('MEDIUM'))();
  TextColumn get status => text().withDefault(const Constant('TODO'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get attemptedAt => dateTime().nullable()();
  DateTimeColumn get solvedAt => dateTime().nullable()();
  TextColumn get solution => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get revisionDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 15. LearningSkills Table (Phase 5 Skill & Competency Tracker)
@DataClassName('LearningSkill')
class LearningSkills extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get category => text().withDefault(const Constant('Technical'))();
  TextColumn get currentLevel => text().withDefault(const Constant('BEGINNER'))();
  TextColumn get targetLevel => text().withDefault(const Constant('ADVANCED'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 16. Resources Table (Phase 5 Reusable Learning Resources)
@DataClassName('Resource')
class Resources extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get url => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('DOCUMENTATION'))();
  TextColumn get category => text().nullable()();
  TextColumn get tags => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('TO_READ'))();
  TextColumn get notes => text().nullable()();
  TextColumn get skillId => text().nullable().references(LearningSkills, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 17. BodyWeights Table (Phase 5 Fitness Body Weight Tracker)
@DataClassName('BodyWeight')
class BodyWeights extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get weight => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 18. Workouts Table (Phase 5 Fitness Workout Log)
@DataClassName('Workout')
class Workouts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  DateTimeColumn get date => dateTime()();
  IntColumn get duration => integer().nullable()(); // duration in minutes
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 19. WorkoutExercises Table (Phase 5 Fitness Exercises in Workout)
@DataClassName('WorkoutExercise')
class WorkoutExercises extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text().references(Workouts, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseName => text().withLength(min: 1, max: 150)();
  IntColumn get sets => integer().withDefault(const Constant(3))();
  IntColumn get reps => integer().withDefault(const Constant(10))();
  RealColumn get weight => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// 20. WorkoutTemplates Table (Phase 5 Fitness Reusable Templates)
@DataClassName('WorkoutTemplate')
class WorkoutTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 21. Incomes Table (Phase 5 Finance Income Tracker)
@DataClassName('Income')
class Incomes extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get source => text().withLength(min: 1, max: 150)();
  TextColumn get category => text().withDefault(const Constant('Salary'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 22. Expenses Table (Phase 5 Finance Expense Tracker)
@DataClassName('Expense')
class Expenses extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get category => text().withDefault(const Constant('Food & Dining'))();
  TextColumn get description => text().withLength(min: 1, max: 200)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 23. AI Conversations Table (Phase 6 AI Assistant)
@DataClassName('AIConversation')
class AIConversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 24. AI Messages Table (Phase 6 AI Assistant)
@DataClassName('AIMessage')
class AIMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text().references(AIConversations, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text()(); // 'user', 'assistant', 'system'
  TextColumn get content => text()();
  TextColumn get contextSummary => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 25. AI Actions Table (Phase 6 AI Assistant Structured Actions)
@DataClassName('AIAction')
class AIActions extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text().references(AIConversations, #id, onDelete: KeyAction.cascade)();
  TextColumn get messageId => text().nullable().references(AIMessages, #id, onDelete: KeyAction.cascade)();
  TextColumn get actionType => text()();
  TextColumn get payload => text()(); // JSON serialized payload
  TextColumn get status => text().withDefault(const Constant('PROPOSED'))(); // 'PROPOSED', 'CONFIRMED', 'CANCELLED', 'EXECUTED', 'FAILED'
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get executedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// 26. AutomationRules Table (Phase 7 Automation & Intelligence)
@DataClassName('AutomationRule')
class AutomationRules extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get type => text()(); // JOB_SEARCH, JOB_MATCHING, APPLICATION_FOLLOWUP, WORK_DEADLINE, EOD_REMINDER, DSA_REVISION, FREELANCE_FOLLOWUP, PROJECT_DEADLINE, WEEKLY_SUMMARY
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get schedule => text().withDefault(const Constant('DAILY_MORNING'))();
  DateTimeColumn get lastRun => dateTime().nullable()();
  DateTimeColumn get nextRun => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('IDLE'))();
  TextColumn get configJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 27. AutomationRuns Table (Phase 7 Automation Logs)
@DataClassName('AutomationRun')
class AutomationRuns extends Table {
  TextColumn get id => text()();
  TextColumn get automationId => text().references(AutomationRules, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('SUCCESS'))(); // SUCCESS, PARTIAL, FAILED
  IntColumn get itemsProcessed => integer().withDefault(const Constant(0))();
  IntColumn get itemsCreated => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// 28. AutomationActions Table (Phase 7 Needs Attention Queue)
@DataClassName('AutomationAction')
class AutomationActions extends Table {
  TextColumn get id => text()();
  TextColumn get automationId => text().nullable().references(AutomationRules, #id, onDelete: KeyAction.setNull)();
  TextColumn get entityType => text()(); // JOB, APPLICATION, TASK, PROJECT, DSA, FREELANCE_LEAD, EOD, WEEKLY_SUMMARY
  TextColumn get entityId => text().nullable()();
  TextColumn get actionType => text()(); // FOLLOW_UP_DUE, DEADLINE_DUE, REVISION_DUE, EOD_MISSING, NEW_MATCHING_JOB, WEEKLY_SUMMARY_READY
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))(); // PENDING, COMPLETED, DISMISSED
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// 29. NotificationSettings Table (Phase 7 Notification Controls)
@DataClassName('NotificationSetting')
class NotificationSettings extends Table {
  TextColumn get id => text()();
  BoolColumn get careerEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get workEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get dsaEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get freelanceEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get projectsEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get weeklyReportsEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get eodReminderTime => text().withDefault(const Constant('18:00'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 30. JobSourceConfigs Table (Phase 7 Job Providers)
@DataClassName('JobSourceConfig')
class JobSourceConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get providerType => text().withDefault(const Constant('RSS_FEED'))(); // RSS_FEED, PUBLIC_API, MOCK
  TextColumn get feedUrl => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastRun => dateTime().nullable()();
  DateTimeColumn get lastSuccess => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  IntColumn get rateLimitMinutes => integer().withDefault(const Constant(60))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 31. ReportRecords Table (Phase 8 Reports Engine)
@DataClassName('ReportRecord')
class ReportRecords extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get reportType => text()(); // WEEKLY, MONTHLY, MODULE_CAREER, MODULE_WORK, MODULE_LEARNING, MODULE_FREELANCE, MODULE_FITNESS, MODULE_FINANCE, CROSS_MODULE
  TextColumn get periodLabel => text()(); // e.g. "This Week", "Sep 2026", "2026-09-01 to 2026-09-25"
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get content => text()(); // Markdown content
  BoolColumn get isAiSynthesized => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 32. BackupRecords Table (Phase 8 Data Management Snapshots)
@DataClassName('BackupRecord')
class BackupRecords extends Table {
  TextColumn get id => text()();
  TextColumn get filename => text().withLength(min: 1, max: 250)();
  TextColumn get backupType => text().withDefault(const Constant('FULL_JSON'))(); // FULL_JSON, CSV_EXPORT
  IntColumn get recordCount => integer().withDefault(const Constant(0))();
  IntColumn get fileSizeBytes => integer().withDefault(const Constant(0))();
  TextColumn get filePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Main App Database ---
@DriftDatabase(tables: [
  UserProfiles,
  Projects,
  Tasks,
  Resumes,
  Jobs,
  JobApplications,
  SavedSearches,
  EODNotes,
  ThingsToAsks,
  WorkNotes,
  Clients,
  FreelanceLeads,
  FreelancePayments,
  DSAProblems,
  LearningSkills,
  Resources,
  BodyWeights,
  Workouts,
  WorkoutExercises,
  WorkoutTemplates,
  Incomes,
  Expenses,
  AIConversations,
  AIMessages,
  AIActions,
  AutomationRules,
  AutomationRuns,
  AutomationActions,
  NotificationSettings,
  JobSourceConfigs,
  ReportRecords,
  BackupRecords,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? impl.connect());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(resumes);
          await m.createTable(savedSearches);
          await m.addColumn(userProfiles, userProfiles.programmingLanguages);
          await m.addColumn(userProfiles, userProfiles.frameworks);
          await m.addColumn(userProfiles, userProfiles.preferredEmploymentType);
          await m.addColumn(userProfiles, userProfiles.noticePeriod);
          await m.addColumn(userProfiles, userProfiles.education);
          await m.addColumn(userProfiles, userProfiles.resumePreferences);
          await m.addColumn(jobs, jobs.experienceRequirement);
          await m.addColumn(jobs, jobs.skills);
          await m.addColumn(jobs, jobs.postedDate);
          await m.addColumn(jobs, jobs.notes);
          await m.addColumn(jobApplications, jobApplications.interviewDate);
          await m.addColumn(jobApplications, jobApplications.interviewStage);
          await m.addColumn(jobApplications, jobApplications.recruiterName);
          await m.addColumn(jobApplications, jobApplications.recruiterContact);
          await m.addColumn(jobApplications, jobApplications.resumeId);
          await m.addColumn(jobApplications, jobApplications.nextAction);
        }
        if (from < 3) {
          await m.createTable(thingsToAsks);
          await m.createTable(workNotes);
          await m.addColumn(tasks, tasks.category);
          await m.addColumn(tasks, tasks.projectId);
          await m.addColumn(tasks, tasks.notes);
          await m.addColumn(projects, projects.deadline);
          await m.addColumn(projects, projects.notes);
          await m.addColumn(eODNotes, eODNotes.notes);
          await m.addColumn(eODNotes, eODNotes.updatedAt);
        }
        if (from < 4) {
          await m.createTable(clients);
          await m.createTable(freelanceLeads);
          await m.createTable(freelancePayments);
          await m.addColumn(projects, projects.clientId);
          await m.addColumn(projects, projects.leadId);
          await m.addColumn(projects, projects.isFreelance);
        }
        if (from < 5) {
          await m.createTable(dSAProblems);
          await m.createTable(learningSkills);
          await m.createTable(resources);
          await m.createTable(bodyWeights);
          await m.createTable(workouts);
          await m.createTable(workoutExercises);
          await m.createTable(workoutTemplates);
          await m.createTable(incomes);
          await m.createTable(expenses);
        }
        if (from < 6) {
          await m.createTable(aIConversations);
          await m.createTable(aIMessages);
          await m.createTable(aIActions);
        }
        if (from < 7) {
          await m.createTable(automationRules);
          await m.createTable(automationRuns);
          await m.createTable(automationActions);
          await m.createTable(notificationSettings);
          await m.createTable(jobSourceConfigs);
        }
        if (from < 8) {
          await m.createTable(reportRecords);
          await m.createTable(backupRecords);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
      },
    );
  }

  // --- Profile Queries ---
  Future<UserProfile?> getProfile() => select(userProfiles).getSingleOrNull();
  Future<UserProfile?> getUserProfile() => getProfile();
  Stream<UserProfile?> watchProfile() => select(userProfiles).watchSingleOrNull();
  Future<int> upsertProfile(UserProfilesCompanion profile) =>
      into(userProfiles).insertOnConflictUpdate(profile);

  // --- Task Queries ---
  Future<List<Task>> getAllTasks() => select(tasks).get();
  Stream<List<Task>> watchAllTasks() => select(tasks).watch();
  Future<Task?> getTaskById(String id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  Stream<List<Task>> watchTasksByProject(String projectId) =>
      (select(tasks)..where((t) => t.projectId.equals(projectId))).watch();
  Future<List<Task>> getTasksByProject(String projectId) =>
      (select(tasks)..where((t) => t.projectId.equals(projectId))).get();
  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);
  Future<bool> updateTask(TasksCompanion task) => update(tasks).replace(task);
  Future<int> deleteTask(String id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();
  Future<int> updateTaskStatus(String id, String status) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Project Queries ---
  Future<List<Project>> getAllProjects() => select(projects).get();
  Stream<List<Project>> watchAllProjects() => select(projects).watch();
  Future<Project?> getProjectById(String id) =>
      (select(projects)..where((p) => p.id.equals(id))).getSingleOrNull();
  Future<int> insertProject(ProjectsCompanion project) => into(projects).insert(project);
  Future<bool> updateProject(ProjectsCompanion project) => update(projects).replace(project);
  Future<int> deleteProject(String id) =>
      (delete(projects)..where((p) => p.id.equals(id))).go();

  // --- Resume Queries (Phase 2) ---
  Future<List<Resume>> getAllResumes() => select(resumes).get();
  Stream<List<Resume>> watchAllResumes() => select(resumes).watch();
  Future<Resume?> getResumeById(String id) =>
      (select(resumes)..where((r) => r.id.equals(id))).getSingleOrNull();
  Future<Resume?> getPrimaryResume() =>
      (select(resumes)..where((r) => r.isPrimary.equals(true))).getSingleOrNull();
  Stream<Resume?> watchPrimaryResume() =>
      (select(resumes)..where((r) => r.isPrimary.equals(true))).watchSingleOrNull();
  Future<int> insertResume(ResumesCompanion resume) => into(resumes).insert(resume);
  Future<bool> updateResume(ResumesCompanion resume) => update(resumes).replace(resume);
  Future<int> deleteResume(String id) =>
      (delete(resumes)..where((r) => r.id.equals(id))).go();

  Future<void> setPrimaryResume(String id) async {
    await transaction(() async {
      await (update(resumes)).write(const ResumesCompanion(isPrimary: Value(false)));
      await (update(resumes)..where((r) => r.id.equals(id)))
          .write(const ResumesCompanion(isPrimary: Value(true)));
    });
  }

  // --- Job Queries ---
  Future<List<Job>> getAllJobs() => select(jobs).get();
  Stream<List<Job>> watchAllJobs() => select(jobs).watch();
  Stream<List<Job>> watchSavedJobs() =>
      (select(jobs)..where((j) => j.isSaved.equals(true))).watch();
  Future<Job?> getJobById(String id) =>
      (select(jobs)..where((j) => j.id.equals(id))).getSingleOrNull();
  Future<int> insertJob(JobsCompanion job) => into(jobs).insert(job);
  Future<bool> updateJob(JobsCompanion job) => update(jobs).replace(job);
  Future<int> deleteJob(String id) =>
      (delete(jobs)..where((j) => j.id.equals(id))).go();
  Future<int> toggleJobSaved(String id, bool saved) =>
      (update(jobs)..where((j) => j.id.equals(id)))
          .write(JobsCompanion(isSaved: Value(saved), updatedAt: Value(DateTime.now())));

  // --- Job Application Queries ---
  Future<List<JobApplication>> getAllApplications() => select(jobApplications).get();
  Stream<List<JobApplication>> watchAllApplications() => select(jobApplications).watch();
  Future<JobApplication?> getApplicationById(String id) =>
      (select(jobApplications)..where((a) => a.id.equals(id))).getSingleOrNull();
  Future<JobApplication?> getApplicationByJobId(String jobId) =>
      (select(jobApplications)..where((a) => a.jobId.equals(jobId))).getSingleOrNull();
  Future<int> insertApplication(JobApplicationsCompanion app) =>
      into(jobApplications).insert(app);
  Future<bool> updateApplication(JobApplicationsCompanion app) =>
      update(jobApplications).replace(app);
  Future<int> deleteApplication(String id) =>
      (delete(jobApplications)..where((a) => a.id.equals(id))).go();
  Future<int> updateApplicationStatus(String id, String status) {
    return (update(jobApplications)..where((a) => a.id.equals(id))).write(
      JobApplicationsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
  Future<List<JobApplication>> getAllJobApplications() => getAllApplications();
  Stream<List<JobApplication>> watchAllJobApplications() => watchAllApplications();

  // --- Saved Searches Queries (Phase 2) ---
  Future<List<SavedSearch>> getAllSavedSearches() => select(savedSearches).get();
  Stream<List<SavedSearch>> watchAllSavedSearches() => select(savedSearches).watch();
  Future<int> insertSavedSearch(SavedSearchesCompanion search) => into(savedSearches).insert(search);
  Future<bool> updateSavedSearch(SavedSearchesCompanion search) => update(savedSearches).replace(search);
  Future<int> deleteSavedSearch(String id) =>
      (delete(savedSearches)..where((s) => s.id.equals(id))).go();

  // --- EOD Note Queries ---
  Future<List<EODNote>> getAllEODNotes() => select(eODNotes).get();
  Stream<List<EODNote>> watchAllEODNotes() => select(eODNotes).watch();
  Future<EODNote?> getEODNoteById(String id) =>
      (select(eODNotes)..where((e) => e.id.equals(id))).getSingleOrNull();
  Future<EODNote?> getEODNoteForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return (select(eODNotes)
          ..where((e) => e.date.isBiggerOrEqualValue(startOfDay) & e.date.isSmallerOrEqualValue(endOfDay)))
        .getSingleOrNull();
  }

  Stream<EODNote?> watchEODNoteForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return (select(eODNotes)
          ..where((e) => e.date.isBiggerOrEqualValue(startOfDay) & e.date.isSmallerOrEqualValue(endOfDay)))
        .watchSingleOrNull();
  }

  Future<int> insertEODNote(EODNotesCompanion note) => into(eODNotes).insert(note);
  Future<bool> updateEODNote(EODNotesCompanion note) => update(eODNotes).replace(note);
  Future<int> deleteEODNote(String id) =>
      (delete(eODNotes)..where((e) => e.id.equals(id))).go();

  // --- Things to Ask Queries (Phase 3) ---
  Future<List<ThingsToAsk>> getAllThingsToAsk() => select(thingsToAsks).get();
  Stream<List<ThingsToAsk>> watchAllThingsToAsk() => select(thingsToAsks).watch();
  Future<int> insertThingToAsk(ThingsToAsksCompanion item) => into(thingsToAsks).insert(item);
  Future<bool> updateThingToAsk(ThingsToAsksCompanion item) => update(thingsToAsks).replace(item);
  Future<int> deleteThingToAsk(String id) =>
      (delete(thingsToAsks)..where((t) => t.id.equals(id))).go();
  Future<int> toggleThingToAskStatus(String id, bool resolve) {
    return (update(thingsToAsks)..where((t) => t.id.equals(id))).write(
      ThingsToAsksCompanion(
        status: Value(resolve ? 'resolved' : 'open'),
        completedAt: Value(resolve ? DateTime.now() : null),
      ),
    );
  }

  // --- Work Notes Queries (Phase 3) ---
  Future<List<WorkNote>> getAllWorkNotes() => select(workNotes).get();
  Stream<List<WorkNote>> watchAllWorkNotes() => select(workNotes).watch();
  Future<WorkNote?> getWorkNoteById(String id) =>
      (select(workNotes)..where((w) => w.id.equals(id))).getSingleOrNull();
  Future<int> insertWorkNote(WorkNotesCompanion note) => into(workNotes).insert(note);
  Future<bool> updateWorkNote(WorkNotesCompanion note) => update(workNotes).replace(note);
  Future<int> deleteWorkNote(String id) =>
      (delete(workNotes)..where((w) => w.id.equals(id))).go();

  // --- Client Queries (Phase 4 Freelance CRM) ---
  Future<List<Client>> getAllClients() => select(clients).get();
  Stream<List<Client>> watchAllClients() => select(clients).watch();
  Future<Client?> getClientById(String id) =>
      (select(clients)..where((c) => c.id.equals(id))).getSingleOrNull();
  Future<int> insertClient(ClientsCompanion client) => into(clients).insert(client);
  Future<bool> updateClient(ClientsCompanion client) => update(clients).replace(client);
  Future<int> deleteClient(String id) =>
      (delete(clients)..where((c) => c.id.equals(id))).go();

  // --- Freelance Lead Queries (Phase 4) ---
  Future<List<FreelanceLead>> getAllLeads() => select(freelanceLeads).get();
  Stream<List<FreelanceLead>> watchAllLeads() => select(freelanceLeads).watch();
  Future<FreelanceLead?> getLeadById(String id) =>
      (select(freelanceLeads)..where((l) => l.id.equals(id))).getSingleOrNull();
  Future<List<FreelanceLead>> getLeadsByClientId(String clientId) =>
      (select(freelanceLeads)..where((l) => l.clientId.equals(clientId))).get();
  Stream<List<FreelanceLead>> watchLeadsByClientId(String clientId) =>
      (select(freelanceLeads)..where((l) => l.clientId.equals(clientId))).watch();
  Future<int> insertLead(FreelanceLeadsCompanion lead) => into(freelanceLeads).insert(lead);
  Future<bool> updateLead(FreelanceLeadsCompanion lead) => update(freelanceLeads).replace(lead);
  Future<int> deleteLead(String id) =>
      (delete(freelanceLeads)..where((l) => l.id.equals(id))).go();
  Future<int> updateLeadStatus(String id, String status) {
    return (update(freelanceLeads)..where((l) => l.id.equals(id))).write(
      FreelanceLeadsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Freelance Payment Queries (Phase 4) ---
  Future<List<FreelancePayment>> getAllPayments() => select(freelancePayments).get();
  Stream<List<FreelancePayment>> watchAllPayments() => select(freelancePayments).watch();
  Future<FreelancePayment?> getPaymentById(String id) =>
      (select(freelancePayments)..where((p) => p.id.equals(id))).getSingleOrNull();
  Future<List<FreelancePayment>> getPaymentsByClientId(String clientId) =>
      (select(freelancePayments)..where((p) => p.clientId.equals(clientId))).get();
  Stream<List<FreelancePayment>> watchPaymentsByClientId(String clientId) =>
      (select(freelancePayments)..where((p) => p.clientId.equals(clientId))).watch();
  Future<List<FreelancePayment>> getPaymentsByProjectId(String projectId) =>
      (select(freelancePayments)..where((p) => p.projectId.equals(projectId))).get();
  Stream<List<FreelancePayment>> watchPaymentsByProjectId(String projectId) =>
      (select(freelancePayments)..where((p) => p.projectId.equals(projectId))).watch();
  Future<int> insertPayment(FreelancePaymentsCompanion payment) =>
      into(freelancePayments).insert(payment);
  Future<bool> updatePayment(FreelancePaymentsCompanion payment) =>
      update(freelancePayments).replace(payment);
  Future<int> deletePayment(String id) =>
      (delete(freelancePayments)..where((p) => p.id.equals(id))).go();
  Future<int> updatePaymentStatus(String id, String status) {
    return (update(freelancePayments)..where((p) => p.id.equals(id))).write(
      FreelancePaymentsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Freelance Project Queries (Phase 4) ---
  Future<List<Project>> getFreelanceProjects() =>
      (select(projects)..where((p) => p.isFreelance.equals(true) | p.clientId.isNotNull())).get();
  Stream<List<Project>> watchFreelanceProjects() =>
      (select(projects)..where((p) => p.isFreelance.equals(true) | p.clientId.isNotNull())).watch();
  Future<List<Project>> getProjectsByClientId(String clientId) =>
      (select(projects)..where((p) => p.clientId.equals(clientId))).get();
  Stream<List<Project>> watchProjectsByClientId(String clientId) =>
      (select(projects)..where((p) => p.clientId.equals(clientId))).watch();

  // --- Phase 5: DSA Queries ---
  Future<List<DSAProblem>> getAllDSAProblems() => select(dSAProblems).get();
  Stream<List<DSAProblem>> watchAllDSAProblems() => select(dSAProblems).watch();
  Future<DSAProblem?> getDSAProblemById(String id) =>
      (select(dSAProblems)..where((p) => p.id.equals(id))).getSingleOrNull();
  Future<int> insertDSAProblem(DSAProblemsCompanion problem) => into(dSAProblems).insert(problem);
  Future<bool> updateDSAProblem(DSAProblemsCompanion problem) => update(dSAProblems).replace(problem);
  Future<int> deleteDSAProblem(String id) =>
      (delete(dSAProblems)..where((p) => p.id.equals(id))).go();
  Future<int> updateDSAStatus(String id, String status) {
    return (update(dSAProblems)..where((p) => p.id.equals(id))).write(
      DSAProblemsCompanion(
        status: Value(status),
        solvedAt: Value(status.toUpperCase() == 'SOLVED' ? DateTime.now() : null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
  Future<int> updateDSARevisionDate(String id, DateTime? revisionDate) {
    return (update(dSAProblems)..where((p) => p.id.equals(id))).write(
      DSAProblemsCompanion(
        revisionDate: Value(revisionDate),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
  Future<int> setDSARevisionDate(String id, DateTime date) => updateDSARevisionDate(id, date);

  // Freelance Aliases
  Future<List<FreelanceLead>> getAllFreelanceLeads() => getAllLeads();
  Stream<List<FreelanceLead>> watchAllFreelanceLeads() => watchAllLeads();
  Future<List<FreelancePayment>> getAllFreelancePayments() => getAllPayments();
  Stream<List<FreelancePayment>> watchAllFreelancePayments() => watchAllPayments();

  // --- Phase 5: Learning Skills Queries ---
  Future<List<LearningSkill>> getAllSkills() => select(learningSkills).get();
  Stream<List<LearningSkill>> watchAllSkills() => select(learningSkills).watch();
  Future<LearningSkill?> getSkillById(String id) =>
      (select(learningSkills)..where((s) => s.id.equals(id))).getSingleOrNull();
  Future<int> insertSkill(LearningSkillsCompanion skill) => into(learningSkills).insert(skill);
  Future<bool> updateSkill(LearningSkillsCompanion skill) => update(learningSkills).replace(skill);
  Future<int> deleteSkill(String id) =>
      (delete(learningSkills)..where((s) => s.id.equals(id))).go();

  // --- Phase 5: Resources Queries ---
  Future<List<Resource>> getAllResources() => select(resources).get();
  Stream<List<Resource>> watchAllResources() => select(resources).watch();
  Future<Resource?> getResourceById(String id) =>
      (select(resources)..where((r) => r.id.equals(id))).getSingleOrNull();
  Future<List<Resource>> getResourcesBySkillId(String skillId) =>
      (select(resources)..where((r) => r.skillId.equals(skillId))).get();
  Stream<List<Resource>> watchResourcesBySkillId(String skillId) =>
      (select(resources)..where((r) => r.skillId.equals(skillId))).watch();
  Future<int> insertResource(ResourcesCompanion resource) => into(resources).insert(resource);
  Future<bool> updateResource(ResourcesCompanion resource) => update(resources).replace(resource);
  Future<int> deleteResource(String id) =>
      (delete(resources)..where((r) => r.id.equals(id))).go();
  Future<int> updateResourceStatus(String id, String status) {
    return (update(resources)..where((r) => r.id.equals(id))).write(
      ResourcesCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Phase 5: Fitness Body Weight Queries ---
  Future<List<BodyWeight>> getAllBodyWeights() =>
      (select(bodyWeights)..orderBy([(w) => OrderingTerm.desc(w.date)])).get();
  Stream<List<BodyWeight>> watchAllBodyWeights() =>
      (select(bodyWeights)..orderBy([(w) => OrderingTerm.desc(w.date)])).watch();
  Future<BodyWeight?> getLatestBodyWeight() =>
      (select(bodyWeights)..orderBy([(w) => OrderingTerm.desc(w.date)])..limit(1)).getSingleOrNull();
  Future<int> insertBodyWeight(BodyWeightsCompanion weight) => into(bodyWeights).insert(weight);
  Future<int> deleteBodyWeight(String id) =>
      (delete(bodyWeights)..where((w) => w.id.equals(id))).go();

  // --- Phase 5: Fitness Workout Queries ---
  Future<List<Workout>> getAllWorkouts() =>
      (select(workouts)..orderBy([(w) => OrderingTerm.desc(w.date)])).get();
  Stream<List<Workout>> watchAllWorkouts() =>
      (select(workouts)..orderBy([(w) => OrderingTerm.desc(w.date)])).watch();
  Future<Workout?> getWorkoutById(String id) =>
      (select(workouts)..where((w) => w.id.equals(id))).getSingleOrNull();
  Future<int> insertWorkout(WorkoutsCompanion workout) => into(workouts).insert(workout);
  Future<bool> updateWorkout(WorkoutsCompanion workout) => update(workouts).replace(workout);
  Future<int> deleteWorkout(String id) =>
      (delete(workouts)..where((w) => w.id.equals(id))).go();

  // --- Phase 5: Workout Exercise Queries ---
  Future<List<WorkoutExercise>> getExercisesForWorkout(String workoutId) =>
      (select(workoutExercises)..where((e) => e.workoutId.equals(workoutId))).get();
  Stream<List<WorkoutExercise>> watchExercisesForWorkout(String workoutId) =>
      (select(workoutExercises)..where((e) => e.workoutId.equals(workoutId))).watch();
  Future<int> insertWorkoutExercise(WorkoutExercisesCompanion exercise) =>
      into(workoutExercises).insert(exercise);
  Future<int> deleteWorkoutExercise(String id) =>
      (delete(workoutExercises)..where((e) => e.id.equals(id))).go();
  Future<int> deleteExercisesForWorkout(String workoutId) =>
      (delete(workoutExercises)..where((e) => e.workoutId.equals(workoutId))).go();

  // --- Phase 5: Workout Template Queries ---
  Future<List<WorkoutTemplate>> getAllWorkoutTemplates() => select(workoutTemplates).get();
  Stream<List<WorkoutTemplate>> watchAllWorkoutTemplates() => select(workoutTemplates).watch();
  Future<int> insertWorkoutTemplate(WorkoutTemplatesCompanion template) =>
      into(workoutTemplates).insert(template);
  Future<bool> updateWorkoutTemplate(WorkoutTemplatesCompanion template) =>
      update(workoutTemplates).replace(template);
  Future<int> deleteWorkoutTemplate(String id) =>
      (delete(workoutTemplates)..where((t) => t.id.equals(id))).go();

  // --- Phase 5: Finance Income Queries ---
  Future<List<Income>> getAllIncomes() =>
      (select(incomes)..orderBy([(i) => OrderingTerm.desc(i.date)])).get();
  Stream<List<Income>> watchAllIncomes() =>
      (select(incomes)..orderBy([(i) => OrderingTerm.desc(i.date)])).watch();
  Future<Income?> getIncomeById(String id) =>
      (select(incomes)..where((i) => i.id.equals(id))).getSingleOrNull();
  Future<int> insertIncome(IncomesCompanion income) => into(incomes).insert(income);
  Future<bool> updateIncome(IncomesCompanion income) => update(incomes).replace(income);
  Future<int> deleteIncome(String id) =>
      (delete(incomes)..where((i) => i.id.equals(id))).go();

  // --- Phase 5: Finance Expense Queries ---
  Future<List<Expense>> getAllExpenses() =>
      (select(expenses)..orderBy([(e) => OrderingTerm.desc(e.date)])).get();
  Stream<List<Expense>> watchAllExpenses() =>
      (select(expenses)..orderBy([(e) => OrderingTerm.desc(e.date)])).watch();
  Future<Expense?> getExpenseById(String id) =>
      (select(expenses)..where((e) => e.id.equals(id))).getSingleOrNull();
  Future<int> insertExpense(ExpensesCompanion expense) => into(expenses).insert(expense);
  Future<bool> updateExpense(ExpensesCompanion expense) => update(expenses).replace(expense);
  Future<int> deleteExpense(String id) =>
      (delete(expenses)..where((e) => e.id.equals(id))).go();

  // --- Phase 6: AI Conversations Queries ---
  Future<List<AIConversation>> getAllAIConversations() =>
      (select(aIConversations)..orderBy([(c) => OrderingTerm.desc(c.updatedAt)])).get();
  Stream<List<AIConversation>> watchAllAIConversations() =>
      (select(aIConversations)..orderBy([(c) => OrderingTerm.desc(c.updatedAt)])).watch();
  Future<AIConversation?> getAIConversationById(String id) =>
      (select(aIConversations)..where((c) => c.id.equals(id))).getSingleOrNull();
  Future<int> insertAIConversation(AIConversationsCompanion conversation) =>
      into(aIConversations).insert(conversation);
  Future<bool> updateAIConversation(AIConversationsCompanion conversation) =>
      update(aIConversations).replace(conversation);
  Future<int> deleteAIConversation(String id) =>
      (delete(aIConversations)..where((c) => c.id.equals(id))).go();

  // --- Phase 6: AI Messages Queries ---
  Future<List<AIMessage>> getAIMessagesForConversation(String conversationId) =>
      (select(aIMessages)
        ..where((m) => m.conversationId.equals(conversationId))
        ..orderBy([(m) => OrderingTerm.asc(m.createdAt)])).get();
  Stream<List<AIMessage>> watchAIMessagesForConversation(String conversationId) =>
      (select(aIMessages)
        ..where((m) => m.conversationId.equals(conversationId))
        ..orderBy([(m) => OrderingTerm.asc(m.createdAt)])).watch();
  Future<int> insertAIMessage(AIMessagesCompanion message) =>
      into(aIMessages).insert(message);
  Future<int> deleteAIMessage(String id) =>
      (delete(aIMessages)..where((m) => m.id.equals(id))).go();

  // --- Phase 6: AI Actions Queries ---
  Future<List<AIAction>> getAIActionsForConversation(String conversationId) =>
      (select(aIActions)
        ..where((a) => a.conversationId.equals(conversationId))
        ..orderBy([(a) => OrderingTerm.asc(a.createdAt)])).get();
  Stream<List<AIAction>> watchAIActionsForConversation(String conversationId) =>
      (select(aIActions)
        ..where((a) => a.conversationId.equals(conversationId))
        ..orderBy([(a) => OrderingTerm.asc(a.createdAt)])).watch();
  Future<AIAction?> getAIActionById(String id) =>
      (select(aIActions)..where((a) => a.id.equals(id))).getSingleOrNull();
  Future<int> insertAIAction(AIActionsCompanion action) =>
      into(aIActions).insert(action);
  Future<bool> updateAIAction(AIActionsCompanion action) =>
      update(aIActions).replace(action);
  Future<int> updateAIActionStatus(String id, String status, {String? errorMessage, DateTime? executedAt}) {
    return (update(aIActions)..where((a) => a.id.equals(id))).write(
      AIActionsCompanion(
        status: Value(status),
        errorMessage: Value(errorMessage),
        executedAt: Value(executedAt),
      ),
    );
  }
  Future<int> deleteAIAction(String id) =>
      (delete(aIActions)..where((a) => a.id.equals(id))).go();

  // --- Phase 7: Automation Rules Queries ---
  Future<List<AutomationRule>> getAllAutomationRules() => select(automationRules).get();
  Stream<List<AutomationRule>> watchAllAutomationRules() => select(automationRules).watch();
  Future<AutomationRule?> getAutomationRuleById(String id) =>
      (select(automationRules)..where((r) => r.id.equals(id))).getSingleOrNull();
  Future<int> insertAutomationRule(AutomationRulesCompanion rule) =>
      into(automationRules).insertOnConflictUpdate(rule);
  Future<bool> updateAutomationRule(AutomationRulesCompanion rule) =>
      update(automationRules).replace(rule);
  Future<int> toggleAutomationRuleEnabled(String id, bool enabled) {
    return (update(automationRules)..where((r) => r.id.equals(id))).write(
      AutomationRulesCompanion(
        enabled: Value(enabled),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
  Future<int> updateAutomationRuleRun(String id, {required String status, DateTime? lastRun, DateTime? nextRun}) {
    return (update(automationRules)..where((r) => r.id.equals(id))).write(
      AutomationRulesCompanion(
        status: Value(status),
        lastRun: Value(lastRun),
        nextRun: Value(nextRun),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Phase 7: Automation Runs Queries ---
  Future<List<AutomationRun>> getRunsForAutomation(String automationId) =>
      (select(automationRuns)
        ..where((r) => r.automationId.equals(automationId))
        ..orderBy([(r) => OrderingTerm.desc(r.startedAt)])).get();
  Stream<List<AutomationRun>> watchRunsForAutomation(String automationId) =>
      (select(automationRuns)
        ..where((r) => r.automationId.equals(automationId))
        ..orderBy([(r) => OrderingTerm.desc(r.startedAt)])).watch();
  Future<List<AutomationRun>> getRecentRuns({int limit = 20}) =>
      (select(automationRuns)
        ..orderBy([(r) => OrderingTerm.desc(r.startedAt)])
        ..limit(limit)).get();
  Stream<List<AutomationRun>> watchRecentRuns({int limit = 20}) =>
      (select(automationRuns)
        ..orderBy([(r) => OrderingTerm.desc(r.startedAt)])
        ..limit(limit)).watch();
  Future<int> insertAutomationRun(AutomationRunsCompanion run) =>
      into(automationRuns).insert(run);

  // --- Phase 7: Automation Actions (Needs Attention Queue) Queries ---
  Future<List<AutomationAction>> getAllPendingActions() =>
      (select(automationActions)
        ..where((a) => a.status.equals('PENDING'))
        ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])).get();
  Stream<List<AutomationAction>> watchAllPendingActions() =>
      (select(automationActions)
        ..where((a) => a.status.equals('PENDING'))
        ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])).watch();
  Future<AutomationAction?> getAutomationActionById(String id) =>
      (select(automationActions)..where((a) => a.id.equals(id))).getSingleOrNull();
  Future<int> insertAutomationAction(AutomationActionsCompanion action) =>
      into(automationActions).insert(action);
  Future<int> updateAutomationActionStatus(String id, String status, {DateTime? completedAt}) {
    return (update(automationActions)..where((a) => a.id.equals(id))).write(
      AutomationActionsCompanion(
        status: Value(status),
        completedAt: Value(completedAt ?? DateTime.now()),
      ),
    );
  }
  Future<int> deleteAutomationAction(String id) =>
      (delete(automationActions)..where((a) => a.id.equals(id))).go();
  Future<bool> isActionDuplicate(String entityType, String? entityId, String actionType) async {
    if (entityId == null) return false;
    final existing = await (select(automationActions)
      ..where((a) =>
          a.entityType.equals(entityType) &
          a.entityId.equals(entityId) &
          a.actionType.equals(actionType) &
          a.status.equals('PENDING'))).get();
    return existing.isNotEmpty;
  }

  // --- Phase 7: Notification Settings Queries ---
  Future<NotificationSetting?> getNotificationSettings() =>
      (select(notificationSettings)..where((s) => s.id.equals('default'))).getSingleOrNull();
  Stream<NotificationSetting?> watchNotificationSettings() =>
      (select(notificationSettings)..where((s) => s.id.equals('default'))).watchSingleOrNull();
  Future<int> upsertNotificationSettings(NotificationSettingsCompanion settings) =>
      into(notificationSettings).insertOnConflictUpdate(settings);

  // --- Phase 7: Job Source Configs Queries ---
  Future<List<JobSourceConfig>> getAllJobSources() => select(jobSourceConfigs).get();
  Stream<List<JobSourceConfig>> watchAllJobSources() => select(jobSourceConfigs).watch();
  Future<JobSourceConfig?> getJobSourceById(String id) =>
      (select(jobSourceConfigs)..where((s) => s.id.equals(id))).getSingleOrNull();
  Future<int> insertJobSource(JobSourceConfigsCompanion source) =>
      into(jobSourceConfigs).insertOnConflictUpdate(source);
  Future<bool> updateJobSource(JobSourceConfigsCompanion source) =>
      update(jobSourceConfigs).replace(source);
  Future<int> toggleJobSourceEnabled(String id, bool enabled) {
    return (update(jobSourceConfigs)..where((s) => s.id.equals(id))).write(
      JobSourceConfigsCompanion(
        enabled: Value(enabled),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
  Future<int> updateJobSourceRunResult(String id, {DateTime? lastRun, DateTime? lastSuccess, String? lastError}) {
    return (update(jobSourceConfigs)..where((s) => s.id.equals(id))).write(
      JobSourceConfigsCompanion(
        lastRun: Value(lastRun),
        lastSuccess: Value(lastSuccess),
        lastError: Value(lastError),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // --- Phase 8: Report Records Queries ---
  Future<List<ReportRecord>> getAllReportRecords() =>
      (select(reportRecords)..orderBy([(r) => OrderingTerm.desc(r.createdAt)])).get();
  Stream<List<ReportRecord>> watchAllReportRecords() =>
      (select(reportRecords)..orderBy([(r) => OrderingTerm.desc(r.createdAt)])).watch();
  Future<ReportRecord?> getReportRecordById(String id) =>
      (select(reportRecords)..where((r) => r.id.equals(id))).getSingleOrNull();
  Future<int> insertReportRecord(ReportRecordsCompanion report) =>
      into(reportRecords).insertOnConflictUpdate(report);
  Future<int> deleteReportRecord(String id) =>
      (delete(reportRecords)..where((r) => r.id.equals(id))).go();

  // --- Phase 8: Backup Records Queries ---
  Future<List<BackupRecord>> getAllBackupRecords() =>
      (select(backupRecords)..orderBy([(b) => OrderingTerm.desc(b.createdAt)])).get();
  Stream<List<BackupRecord>> watchAllBackupRecords() =>
      (select(backupRecords)..orderBy([(b) => OrderingTerm.desc(b.createdAt)])).watch();
  Future<int> insertBackupRecord(BackupRecordsCompanion backup) =>
      into(backupRecords).insertOnConflictUpdate(backup);
  Future<int> deleteBackupRecord(String id) =>
      (delete(backupRecords)..where((b) => b.id.equals(id))).go();
}

// Global Provider for AppDatabase instance
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
