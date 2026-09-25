import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/features/automation/data/job_providers/mock_job_provider.dart';
import 'package:career_os/features/automation/data/notification_service.dart';
import 'package:career_os/features/automation/domain/automation_models.dart';
import 'package:career_os/features/automation/domain/automation_rule_evaluator.dart';
import 'package:career_os/features/automation/domain/job_deduplicator.dart';
import 'package:career_os/features/automation/domain/job_normalizer.dart';
import 'package:career_os/features/automation/domain/weekly_summary_aggregator.dart';
import 'package:career_os/features/automation/services/automation_engine.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 7: Job Normalizer & Deduplicator Tests', () {
    test('JobNormalizer cleans whitespace and formats companion', () {
      const raw = RawJobItem(
        title: '   Senior   Flutter   Dev  ',
        company: '  Google Inc  ',
        location: ' Remote ',
        skills: 'Flutter,  Dart ',
        url: 'https://careers.google.com/jobs/123?ref=feed&utm=test',
        description: '<p>Awesome role</p>',
      );

      final companion = JobNormalizer.normalize(raw);
      expect(companion.title.value, equals('Senior Flutter Dev'));
      expect(companion.company.value, equals('Google Inc'));
      expect(companion.location.value, equals('Remote'));
      expect(companion.skills.value, equals('Flutter, Dart'));
      expect(companion.url.value, equals('https://careers.google.com/jobs/123?ref=feed&utm=test'));
    });

    test('JobDeduplicator detects duplicate canonical URLs', () {
      final existingJobs = [
        Job(
          id: 'job-1',
          title: 'Staff Flutter Engineer',
          company: 'Acme Corp',
          url: 'https://example.com/jobs/456',
          discoveredAt: DateTime.now(),
          isSaved: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      const duplicateRaw = RawJobItem(
        title: 'Different Title',
        company: 'Acme',
        url: 'https://example.com/jobs/456?source=newsletter',
      );

      final result = JobDeduplicator.isDuplicate(duplicateRaw, existingJobs);
      expect(result.isDuplicate, isTrue);
      expect(result.matchedJobId, equals('job-1'));
    });

    test('JobDeduplicator detects matching company and title', () {
      final existingJobs = [
        Job(
          id: 'job-2',
          title: 'Backend Engineer',
          company: 'Stripe',
          url: 'https://stripe.com/job1',
          discoveredAt: DateTime.now(),
          isSaved: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      const duplicateRaw = RawJobItem(
        title: 'Backend Engineer',
        company: 'Stripe',
        url: 'https://another-feed.com/stripe-job',
      );

      final result = JobDeduplicator.isDuplicate(duplicateRaw, existingJobs);
      expect(result.isDuplicate, isTrue);
      expect(result.matchedJobId, equals('job-2'));
    });

    test('JobDeduplicator allows genuinely new jobs', () {
      final existingJobs = [
        Job(
          id: 'job-3',
          title: 'Mobile Engineer',
          company: 'Uber',
          url: 'https://uber.com/1',
          discoveredAt: DateTime.now(),
          isSaved: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      const newRaw = RawJobItem(
        title: 'Mobile Engineer',
        company: 'Lyft',
        url: 'https://lyft.com/1',
      );

      final result = JobDeduplicator.isDuplicate(newRaw, existingJobs);
      expect(result.isDuplicate, isFalse);
    });
  });

  group('Phase 7: Automation Rule Evaluation Tests', () {
    test('JOB_SEARCH runs saved search, deduplicates, and saves new jobs', () async {
      await db.insertSavedSearch(SavedSearchesCompanion(
        id: const Value('search-1'),
        name: const Value('Flutter Remote'),
        jobTitle: const Value('Flutter Developer'),
        keywords: const Value('Flutter, Dart'),
        remotePreference: const Value('remote'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final mockProvider = MockJobProvider();
      final evaluator = AutomationRuleEvaluator(
        db: db,
        jobProviders: [mockProvider],
      );

      final rule = AutomationRule(
        id: 'auto_job_search',
        name: 'Job Search',
        type: 'JOB_SEARCH',
        enabled: true,
        schedule: 'DAILY_MORNING',
        status: 'IDLE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await evaluator.evaluate(rule);
      expect(result.isSuccess, isTrue);
      expect(result.itemsCreated, greaterThan(0));

      final jobsInDb = await db.getAllJobs();
      expect(jobsInDb.any((j) => j.title.contains('Flutter')), isTrue);
    });

    test('APPLICATION_FOLLOWUP detects overdue and due today follow-ups', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      await db.insertApplication(JobApplicationsCompanion(
        id: const Value('app-1'),
        company: const Value('Airbnb'),
        role: const Value('Senior iOS/Flutter Engineer'),
        status: const Value('interview'),
        followUpDate: Value(yesterday),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      await db.insertApplication(JobApplicationsCompanion(
        id: const Value('app-2'),
        company: const Value('Spotify'),
        role: const Value('Platform Architect'),
        status: const Value('rejected'), // Rejected, should be ignored
        followUpDate: Value(today),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final evaluator = AutomationRuleEvaluator(db: db);
      final rule = AutomationRule(
        id: 'auto_app_followup',
        name: 'Follow-ups',
        type: 'APPLICATION_FOLLOWUP',
        enabled: true,
        schedule: 'DAILY_MORNING',
        status: 'IDLE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await evaluator.evaluate(rule);
      expect(result.isSuccess, isTrue);
      expect(result.proposedActions.length, equals(1));
      expect(result.proposedActions.first.entityId, equals('app-1'));
    });

    test('WORK_DEADLINE detects tasks due today or overdue and excludes completed', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await db.insertTask(TasksCompanion(
        id: const Value('task-1'),
        title: const Value('Implement Auth Flow'),
        category: const Value('work'),
        status: const Value('in_progress'),
        dueDate: Value(today),
      ));

      await db.insertTask(TasksCompanion(
        id: const Value('task-2'),
        title: const Value('Setup CI Pipeline'),
        category: const Value('work'),
        status: const Value('completed'), // Completed, should be excluded
        dueDate: Value(today),
      ));

      final evaluator = AutomationRuleEvaluator(db: db);
      final rule = AutomationRule(
        id: 'auto_work_deadline',
        name: 'Work Deadlines',
        type: 'WORK_DEADLINE',
        enabled: true,
        schedule: 'DAILY_MORNING',
        status: 'IDLE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await evaluator.evaluate(rule);
      expect(result.isSuccess, isTrue);
      expect(result.proposedActions.length, equals(1));
      expect(result.proposedActions.first.entityId, equals('task-1'));
    });

    test('EOD_REMINDER detects missing EOD for today', () async {
      final evaluator = AutomationRuleEvaluator(db: db);
      final rule = AutomationRule(
        id: 'auto_eod_reminder',
        name: 'EOD Reminder',
        type: 'EOD_REMINDER',
        enabled: true,
        schedule: 'DAILY_EVENING',
        status: 'IDLE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await evaluator.evaluate(rule);
      expect(result.isSuccess, isTrue);
      expect(result.proposedActions.length, equals(1));
      expect(result.proposedActions.first.actionType, equals('EOD_MISSING'));

      // If EOD is inserted, reminder should not trigger an action
      await db.insertEODNote(EODNotesCompanion(
        id: const Value('eod-1'),
        date: Value(DateTime.now()),
        completedWork: const Value('Completed Phase 7 features'),
        inProgressWork: const Value('Writing test cases'),
        createdAt: Value(DateTime.now()),
      ));

      final resultAfter = await evaluator.evaluate(rule);
      expect(resultAfter.proposedActions.isEmpty, isTrue);
    });

    test('DSA_REVISION detects problems ready for spaced repetition', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await db.insertDSAProblem(DSAProblemsCompanion(
        id: const Value('dsa-1'),
        title: const Value('Trapping Rain Water'),
        platform: const Value('LeetCode'),
        topic: const Value('Two Pointers'),
        difficulty: const Value('Hard'),
        revisionDate: Value(today),
      ));

      final evaluator = AutomationRuleEvaluator(db: db);
      final rule = AutomationRule(
        id: 'auto_dsa_revision',
        name: 'DSA Revision',
        type: 'DSA_REVISION',
        enabled: true,
        schedule: 'DAILY_MORNING',
        status: 'IDLE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await evaluator.evaluate(rule);
      expect(result.isSuccess, isTrue);
      expect(result.proposedActions.length, equals(1));
      expect(result.proposedActions.first.entityId, equals('dsa-1'));
    });
  });

  group('Phase 7: Weekly Summary Aggregator Tests', () {
    test('WeeklySummaryAggregator compiles factual statistics across modules', () async {
      final now = DateTime.now();

      // Insert tasks, jobs, workouts, finances
      await db.insertTask(TasksCompanion(
        id: const Value('task-w1'),
        title: const Value('Shipped Phase 7'),
        category: const Value('work'),
        status: const Value('completed'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      await db.insertDSAProblem(DSAProblemsCompanion(
        id: const Value('dsa-w1'),
        title: const Value('Merge Intervals'),
        status: const Value('SOLVED'),
        solvedAt: Value(now),
        createdAt: Value(now),
      ));

      await db.insertIncome(IncomesCompanion(
        id: const Value('inc-w1'),
        amount: const Value(3000.0),
        source: const Value('Monthly Salary'),
        date: Value(now),
      ));

      await db.insertExpense(ExpensesCompanion(
        id: const Value('exp-w1'),
        amount: const Value(500.0),
        description: const Value('Groceries'),
        date: Value(now),
      ));

      final aggregator = WeeklySummaryAggregator(db);
      final summary = await aggregator.aggregate();

      expect(summary.tasksCompleted, equals(1));
      expect(summary.dsaProblemsSolved, equals(1));
      expect(summary.totalIncome, equals(3000.0));
      expect(summary.totalExpense, equals(500.0));
      expect(summary.netSavings, equals(2500.0));

      final markdown = summary.toMarkdownReport();
      expect(markdown, contains('# 📊 Weekly Career OS Summary'));
      expect(markdown, contains('Completed Tasks: **1**'));
      expect(markdown, contains('Net Savings: **\$2500.00**'));
    });
  });

  group('Phase 7: Automation Engine & Logging Tests', () {
    test('AutomationEngine initializes default rules, logs runs, and executes safely', () async {
      final mockProvider = MockJobProvider();
      final engine = AutomationEngine(
        db: db,
        customProviders: [mockProvider],
      );

      await engine.initialize();
      final rules = await db.getAllAutomationRules();
      expect(rules.length, equals(9));

      // Run specific rule
      final result = await engine.runAutomation('auto_work_deadline');
      expect(result.isSuccess, isTrue);

      // Check run history log
      final runs = await db.getRecentRuns();
      expect(runs.length, equals(1));
      expect(runs.first.status, equals('SUCCESS'));
    });

    test('AutomationEngine handles provider error without crashing app', () async {
      await db.insertSavedSearch(SavedSearchesCompanion(
        id: const Value('search-err'),
        name: const Value('Backend Search'),
        jobTitle: const Value('Backend'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final failingProvider = MockJobProvider(shouldFail: true);
      final engine = AutomationEngine(
        db: db,
        customProviders: [failingProvider],
      );
      await engine.initialize();

      final result = await engine.runAutomation('auto_job_search');
      expect(result.isSuccess, isTrue); // Handled safely and recorded in messages
      expect(result.messages.any((m) => m.contains('Simulated provider connection failure')), isTrue);
    });

    test('NotificationSettings filters categories properly', () async {
      final notifService = AppNotificationService();
      final settings = NotificationSetting(
        id: 'default',
        careerEnabled: true,
        workEnabled: false, // Disabled
        dsaEnabled: true,
        freelanceEnabled: true,
        projectsEnabled: true,
        weeklyReportsEnabled: true,
        eodReminderTime: '18:00',
        updatedAt: DateTime.now(),
      );

      // Career notification should go through
      await notifService.showNotification(
        id: 1,
        title: 'Career alert',
        body: 'New job',
        category: NotificationCategory.career,
        settings: settings,
      );

      // Work notification should be ignored
      await notifService.showNotification(
        id: 2,
        title: 'Work alert',
        body: 'Deadline',
        category: NotificationCategory.work,
        settings: settings,
      );

      expect(notifService.recentNotifications.any((n) => n.id == 1), isTrue);
      expect(notifService.recentNotifications.any((n) => n.id == 2), isFalse);
    });
  });
}
