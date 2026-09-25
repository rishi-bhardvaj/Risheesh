import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../data/job_providers/job_provider.dart';
import '../data/notification_service.dart';
import '../domain/automation_models.dart';
import '../domain/automation_rule_evaluator.dart';

class AutomationEngine {
  final AppDatabase db;
  final List<JobProvider>? customProviders;
  final AppNotificationService _notificationService;
  final _uuid = const Uuid();

  AutomationEngine({
    required this.db,
    this.customProviders,
    AppNotificationService? notificationService,
  }) : _notificationService = notificationService ?? AppNotificationService();

  Future<void> initialize() async {
    final existingRules = await db.getAllAutomationRules();
    if (existingRules.isEmpty) {
      final now = DateTime.now();
      final defaultRules = [
        AutomationRulesCompanion(
          id: const Value('auto_job_search'),
          name: const Value('Automated Job Feed Search'),
          description: const Value('Queries configured RSS job feeds against your saved searches'),
          type: const Value('JOB_SEARCH'),
          schedule: const Value('DAILY_MORNING'),
          enabled: const Value(true),
          status: const Value('IDLE'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        AutomationRulesCompanion(
          id: const Value('auto_job_matching'),
          name: const Value('Profile Skill Job Matcher'),
          description: const Value('Calculates transparent skill match percentage for newly discovered jobs'),
          type: const Value('JOB_MATCHING'),
          schedule: const Value('DAILY_MORNING'),
          enabled: const Value(true),
          status: const Value('IDLE'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        AutomationRulesCompanion(
          id: const Value('auto_app_followup'),
          name: const Value('Job Application Follow-up Tracker'),
          description: const Value('Detects pending job applications where follow-up date is due or overdue'),
          type: const Value('APPLICATION_FOLLOWUP'),
          schedule: const Value('DAILY_MORNING'),
          enabled: const Value(true),
          status: const Value('IDLE'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        AutomationRulesCompanion(
          id: const Value('auto_work_deadline'),
          name: const Value('Work Task Deadline Watcher'),
          description: const Value('Surfaces work tasks due today or overdue'),
          type: const Value('WORK_DEADLINE'),
          schedule: const Value('DAILY_MORNING'),
          enabled: const Value(true),
          status: const Value('IDLE'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        AutomationRulesCompanion(
          id: const Value('auto_eod_reminder'),
          name: const Value('Daily EOD Standup Reminder'),
          description: const Value('Prompts user to complete their daily End-Of-Day work summary'),
          type: const Value('EOD_REMINDER'),
          schedule: const Value('DAILY_EVENING'),
          enabled: const Value(true),
          status: const Value('IDLE'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        AutomationRulesCompanion(
          id: const Value('auto_dsa_revision'),
          name: const Value('DSA Spaced Repetition Revision'),
          description: const Value('Flags DSA problems scheduled for spaced repetition review'),
          type: const Value('DSA_REVISION'),
          schedule: const Value('DAILY_MORNING'),
          enabled: const Value(true),
          status: const Value('IDLE'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        AutomationRulesCompanion(
          id: const Value('auto_freelance_followup'),
          name: const Value('Freelance Lead Follow-up Reminder'),
          description: const Value('Checks active freelance proposals and leads scheduled for follow-up'),
          type: const Value('FREELANCE_FOLLOWUP'),
          schedule: const Value('DAILY_MORNING'),
          enabled: const Value(true),
          status: const Value('IDLE'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        AutomationRulesCompanion(
          id: const Value('auto_project_deadline'),
          name: const Value('Active Project Deadline Watcher'),
          description: const Value('Monitors approaching project milestones and deadlines within 3 days'),
          type: const Value('PROJECT_DEADLINE'),
          schedule: const Value('DAILY_MORNING'),
          enabled: const Value(true),
          status: const Value('IDLE'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        AutomationRulesCompanion(
          id: const Value('auto_weekly_summary'),
          name: const Value('Weekly Multi-Module Progress Digest'),
          description: const Value('Compiles cross-module accomplishments and financial summary'),
          type: const Value('WEEKLY_SUMMARY'),
          schedule: const Value('WEEKLY'),
          enabled: const Value(true),
          status: const Value('IDLE'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ];

      for (final rule in defaultRules) {
        await db.insertAutomationRule(rule);
      }
    }
  }

  Future<RuleEvaluationResult> runAutomation(String ruleId) async {
    final rule = await db.getAutomationRuleById(ruleId);
    if (rule == null) {
      return RuleEvaluationResult(
        ruleId: ruleId,
        isSuccess: false,
        messages: ['Rule $ruleId not found'],
      );
    }

    final startTime = DateTime.now();
    await db.updateAutomationRuleRun(ruleId, status: 'RUNNING');

    final evaluator = AutomationRuleEvaluator(
      db: db,
      jobProviders: customProviders,
    );

    RuleEvaluationResult result;
    try {
      result = await evaluator.evaluate(rule);

      // Save proposed actions idempotently to AutomationActions table
      final existingPendingActions = await db.getAllPendingActions();
      for (final action in result.proposedActions) {
        final isDup = existingPendingActions.any((a) =>
            a.actionType == action.actionType &&
            a.entityType == action.entityType &&
            a.entityId == action.entityId);

        if (!isDup) {
          await db.insertAutomationAction(AutomationActionsCompanion(
            id: Value(_uuid.v4()),
            automationId: Value(rule.id),
            actionType: Value(action.actionType),
            title: Value(action.title),
            description: Value(action.description),
            entityType: Value(action.entityType),
            entityId: Value(action.entityId),
            status: const Value('PENDING'),
            createdAt: Value(DateTime.now()),
          ));

          // Trigger local notification for actionable alert
          final notifCategory = _mapCategory(action.entityType);
          final settings = await db.getNotificationSettings();
          await _notificationService.showNotification(
            id: action.title.hashCode & 0x7FFFFFFF,
            title: action.title,
            body: action.description,
            category: notifCategory,
            settings: settings,
            payload: jsonEncode({
              'entityType': action.entityType,
              'entityId': action.entityId,
            }),
          );
        }
      }

      final finishTime = DateTime.now();

      // Record run log
      await db.insertAutomationRun(AutomationRunsCompanion(
        id: Value(_uuid.v4()),
        automationId: Value(rule.id),
        startedAt: Value(startTime),
        finishedAt: Value(finishTime),
        status: const Value('SUCCESS'),
        itemsProcessed: Value(result.itemsEvaluated),
        itemsCreated: Value(result.itemsCreated),
        errorMessage: Value(result.messages.isNotEmpty ? result.messages.join('; ') : null),
      ));

      await db.updateAutomationRuleRun(ruleId, status: 'SUCCESS', lastRun: finishTime);
    } catch (e) {
      final finishTime = DateTime.now();

      await db.insertAutomationRun(AutomationRunsCompanion(
        id: Value(_uuid.v4()),
        automationId: Value(rule.id),
        startedAt: Value(startTime),
        finishedAt: Value(finishTime),
        status: const Value('FAILED'),
        itemsProcessed: const Value(0),
        itemsCreated: const Value(0),
        errorMessage: Value('Execution error: $e'),
      ));

      await db.updateAutomationRuleRun(ruleId, status: 'FAILED', lastRun: finishTime);

      result = RuleEvaluationResult(
        ruleId: rule.id,
        isSuccess: false,
        messages: ['Failed execution: $e'],
      );
    }

    return result;
  }

  Future<List<RuleEvaluationResult>> runAllEnabledRules() async {
    final rules = await db.getAllAutomationRules();
    final List<RuleEvaluationResult> results = [];
    for (final rule in rules) {
      if (rule.enabled) {
        final res = await runAutomation(rule.id);
        results.add(res);
      }
    }
    return results;
  }

  NotificationCategory _mapCategory(String entityType) {
    switch (entityType) {
      case 'job':
      case 'application':
        return NotificationCategory.career;
      case 'task':
      case 'eod_note':
        return NotificationCategory.work;
      case 'dsa_problem':
        return NotificationCategory.dsa;
      case 'freelance_lead':
      case 'freelance_milestone':
        return NotificationCategory.freelance;
      case 'project':
        return NotificationCategory.projects;
      case 'weekly_summary':
      default:
        return NotificationCategory.weeklySummary;
    }
  }
}
