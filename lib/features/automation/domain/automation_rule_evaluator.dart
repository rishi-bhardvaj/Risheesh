import '../../../core/database/app_database.dart';
import '../data/job_providers/job_provider.dart';
import '../data/job_providers/rss_job_provider.dart';
import 'automation_models.dart';
import 'job_deduplicator.dart';
import 'job_normalizer.dart';
import 'weekly_summary_aggregator.dart';

class AutomationRuleEvaluator {
  final AppDatabase db;
  final List<JobProvider> jobProviders;

  AutomationRuleEvaluator({
    required this.db,
    List<JobProvider>? jobProviders,
  }) : jobProviders = jobProviders ??
            [
              RssJobProvider(
                providerId: 'remote_ok',
                providerName: 'RemoteOK',
                feedUrl: 'https://remoteok.com/remote-jobs.rss',
              ),
              RssJobProvider(
                providerId: 'we_work_remotely',
                providerName: 'WeWorkRemotely',
                feedUrl: 'https://weworkremotely.com/remote-jobs.rss',
              ),
            ];

  Future<RuleEvaluationResult> evaluate(AutomationRule rule) async {
    switch (rule.type) {
      case 'JOB_SEARCH':
        return _evaluateJobSearch(rule);
      case 'JOB_MATCHING':
        return _evaluateJobMatching(rule);
      case 'APPLICATION_FOLLOWUP':
        return _evaluateApplicationFollowup(rule);
      case 'WORK_DEADLINE':
        return _evaluateWorkDeadline(rule);
      case 'EOD_REMINDER':
        return _evaluateEODReminder(rule);
      case 'DSA_REVISION':
        return _evaluateDSARevision(rule);
      case 'FREELANCE_FOLLOWUP':
        return _evaluateFreelanceFollowup(rule);
      case 'PROJECT_DEADLINE':
        return _evaluateProjectDeadline(rule);
      case 'WEEKLY_SUMMARY':
        return _evaluateWeeklySummary(rule);
      default:
        return RuleEvaluationResult(
          ruleId: rule.id,
          isSuccess: false,
          messages: ['Unknown rule type: ${rule.type}'],
        );
    }
  }

  Future<RuleEvaluationResult> _evaluateJobSearch(AutomationRule rule) async {
    final savedSearches = await db.getAllSavedSearches();
    final existingJobs = await db.getAllJobs();

    int totalDiscovered = 0;
    int totalNewSaved = 0;
    final List<String> logs = [];

    // Search for each saved search or general search
    final queries = savedSearches.isNotEmpty
        ? savedSearches.map((s) => s.jobTitle ?? s.name).toList()
        : ['Flutter', 'Mobile', 'Backend'];

    for (final provider in jobProviders) {
      for (final query in queries) {
        try {
          final rawJobs = await provider.searchJobs(query: query);
          totalDiscovered += rawJobs.length;

          for (final raw in rawJobs) {
            final dedupe = JobDeduplicator.isDuplicate(raw, existingJobs);
            if (!dedupe.isDuplicate) {
              final companion = JobNormalizer.normalize(raw);
              await db.insertJob(companion);
              // Add to existing in-memory to deduplicate subsequent items in this run
              final savedJob = Job(
                id: companion.id.value,
                title: companion.title.value,
                company: companion.company.value,
                location: companion.location.value,
                salary: companion.salary.value,
                employmentType: companion.employmentType.value,
                experienceRequirement: null,
                postedDate: null,
                skills: companion.skills.value,
                url: companion.url.value,
                description: companion.description.value,
                discoveredAt: companion.discoveredAt.value,
                isSaved: companion.isSaved.value,
                source: companion.source.value,
                notes: null,
                createdAt: companion.createdAt.value,
                updatedAt: companion.updatedAt.value,
              );
              existingJobs.add(savedJob);
              totalNewSaved++;
            }
          }
        } catch (e) {
          logs.add('Provider ${provider.providerName} query "$query" error: $e');
        }
      }
    }

    logs.add('Discovered $totalDiscovered raw items; Saved $totalNewSaved new unique jobs');
    return RuleEvaluationResult(
      ruleId: rule.id,
      isSuccess: true,
      itemsEvaluated: totalDiscovered,
      itemsCreated: totalNewSaved,
      messages: logs,
    );
  }

  Future<RuleEvaluationResult> _evaluateJobMatching(AutomationRule rule) async {
    final profile = await db.getUserProfile();
    final combinedSkills = '${profile?.skills ?? ""}, ${profile?.programmingLanguages ?? ""}, ${profile?.frameworks ?? ""}';
    final skillsList = combinedSkills
        .toLowerCase()
        .split(RegExp(r'[,| ]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 1)
        .toSet()
        .toList();

    if (profile == null || skillsList.isEmpty) {
      return RuleEvaluationResult(
        ruleId: rule.id,
        isSuccess: true,
        messages: ['No user profile or skills configured for matching'],
      );
    }

    final allJobs = await db.getAllJobs();
    final List<ActionProposalItem> matches = [];

    for (final job in allJobs) {
      final jobContent = '${job.title} ${job.skills ?? ''} ${job.description ?? ''}'.toLowerCase();
      int matchCount = 0;
      for (final s in skillsList) {
        if (jobContent.contains(s)) matchCount++;
      }

      if (matchCount > 0 && !job.isSaved) {
        final score = ((matchCount / skillsList.length) * 100).clamp(0, 100).round();
        if (score >= 40) {
          matches.add(ActionProposalItem(
            actionType: 'JOB_MATCH',
            title: 'Matching Role: ${job.title} at ${job.company}',
            description: '$score% profile match based on skills ($matchCount matching).',
            entityType: 'job',
            entityId: job.id,
            payload: {'jobId': job.id, 'matchScore': score},
            urgency: score >= 70 ? 'HIGH' : 'MEDIUM',
          ));
        }
      }
    }

    return RuleEvaluationResult(
      ruleId: rule.id,
      isSuccess: true,
      itemsEvaluated: allJobs.length,
      itemsCreated: matches.length,
      proposedActions: matches,
      messages: ['Evaluated ${allJobs.length} jobs; found ${matches.length} matches'],
    );
  }

  Future<RuleEvaluationResult> _evaluateApplicationFollowup(AutomationRule rule) async {
    final allApps = await db.getAllApplications();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final List<ActionProposalItem> actions = [];

    for (final app in allApps) {
      if (app.status == 'rejected' || app.status == 'offer' || app.status == 'withdrawn') {
        continue;
      }

      if (app.followUpDate != null && app.followUpDate!.isBefore(today)) {
        final isOverdue = app.followUpDate!.isBefore(DateTime(now.year, now.month, now.day));
        actions.add(ActionProposalItem(
          actionType: 'APPLICATION_FOLLOWUP',
          title: '${isOverdue ? "Overdue" : "Due Today"}: Follow-up with ${app.company}',
          description: 'Follow-up for ${app.role} (${app.status.toUpperCase()}).',
          entityType: 'application',
          entityId: app.id,
          payload: {'applicationId': app.id, 'company': app.company, 'role': app.role},
          urgency: isOverdue ? 'HIGH' : 'MEDIUM',
        ));
      }
    }

    return RuleEvaluationResult(
      ruleId: rule.id,
      isSuccess: true,
      itemsEvaluated: allApps.length,
      itemsCreated: actions.length,
      proposedActions: actions,
      messages: ['Found ${actions.length} applications requiring follow-up'],
    );
  }

  Future<RuleEvaluationResult> _evaluateWorkDeadline(AutomationRule rule) async {
    final allTasks = await db.getAllTasks();
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final List<ActionProposalItem> actions = [];

    for (final task in allTasks) {
      if (task.status == 'completed' || task.category != 'work') {
        continue;
      }

      if (task.dueDate != null && task.dueDate!.isBefore(todayEnd)) {
        final isOverdue = task.dueDate!.isBefore(DateTime(now.year, now.month, now.day));
        actions.add(ActionProposalItem(
          actionType: 'WORK_TASK_DEADLINE',
          title: '${isOverdue ? "Overdue" : "Due Today"}: ${task.title}',
          description: 'Work task deadline (${task.priority.toUpperCase()} priority).',
          entityType: 'task',
          entityId: task.id,
          payload: {'taskId': task.id, 'priority': task.priority},
          urgency: isOverdue || task.priority == 'high' ? 'HIGH' : 'MEDIUM',
        ));
      }
    }

    return RuleEvaluationResult(
      ruleId: rule.id,
      isSuccess: true,
      itemsEvaluated: allTasks.length,
      itemsCreated: actions.length,
      proposedActions: actions,
      messages: ['Found ${actions.length} work tasks due or overdue'],
    );
  }

  Future<RuleEvaluationResult> _evaluateEODReminder(AutomationRule rule) async {
    final todayEod = await db.getEODNoteForDate(DateTime.now());
    final List<ActionProposalItem> actions = [];

    if (todayEod == null) {
      actions.add(const ActionProposalItem(
        actionType: 'EOD_MISSING',
        title: 'Daily Standup EOD Missing',
        description: 'Log your completed work, blockers, and next focus before ending your day.',
        entityType: 'eod_note',
        urgency: 'MEDIUM',
      ));
    }

    return RuleEvaluationResult(
      ruleId: rule.id,
      isSuccess: true,
      itemsEvaluated: 1,
      itemsCreated: actions.length,
      proposedActions: actions,
      messages: [todayEod == null ? 'EOD note not yet logged today' : 'EOD note already submitted'],
    );
  }

  Future<RuleEvaluationResult> _evaluateDSARevision(AutomationRule rule) async {
    final allDsa = await db.getAllDSAProblems();
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final List<ActionProposalItem> actions = [];

    for (final dsa in allDsa) {
      if (dsa.revisionDate != null && dsa.revisionDate!.isBefore(todayEnd)) {
        actions.add(ActionProposalItem(
          actionType: 'DSA_REVISION_DUE',
          title: 'DSA Revision: ${dsa.title}',
          description: 'Topic: ${dsa.topic} | Platform: ${dsa.platform}',
          entityType: 'dsa_problem',
          entityId: dsa.id,
          payload: {'dsaId': dsa.id, 'title': dsa.title},
          urgency: 'MEDIUM',
        ));
      }
    }

    return RuleEvaluationResult(
      ruleId: rule.id,
      isSuccess: true,
      itemsEvaluated: allDsa.length,
      itemsCreated: actions.length,
      proposedActions: actions,
      messages: ['Found ${actions.length} DSA problems due for spaced repetition'],
    );
  }

  Future<RuleEvaluationResult> _evaluateFreelanceFollowup(AutomationRule rule) async {
    final allLeads = await db.getAllFreelanceLeads();
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final List<ActionProposalItem> actions = [];

    for (final lead in allLeads) {
      if (lead.status == 'WON' || lead.status == 'LOST') {
        continue;
      }

      if (lead.followUpDate != null && lead.followUpDate!.isBefore(todayEnd)) {
        actions.add(ActionProposalItem(
          actionType: 'FREELANCE_FOLLOWUP',
          title: 'Freelance Follow-up: ${lead.clientName ?? lead.title}',
          description: 'Project: ${lead.title} (Status: ${lead.status}).',
          entityType: 'freelance_lead',
          entityId: lead.id,
          payload: {'leadId': lead.id, 'clientName': lead.clientName},
          urgency: 'MEDIUM',
        ));
      }
    }

    return RuleEvaluationResult(
      ruleId: rule.id,
      isSuccess: true,
      itemsEvaluated: allLeads.length,
      itemsCreated: actions.length,
      proposedActions: actions,
      messages: ['Found ${actions.length} freelance leads ready for follow-up'],
    );
  }

  Future<RuleEvaluationResult> _evaluateProjectDeadline(AutomationRule rule) async {
    final allProjects = await db.getAllProjects();
    final now = DateTime.now();
    final threeDaysOut = now.add(const Duration(days: 3));

    final List<ActionProposalItem> actions = [];

    for (final proj in allProjects) {
      if (proj.status == 'COMPLETED' || proj.status == 'ARCHIVED') {
        continue;
      }

      if (proj.deadline != null && proj.deadline!.isBefore(threeDaysOut)) {
        final isOverdue = proj.deadline!.isBefore(now);
        actions.add(ActionProposalItem(
          actionType: 'PROJECT_DEADLINE',
          title: '${isOverdue ? "Overdue Project" : "Upcoming Deadline"}: ${proj.name}',
          description: 'Target deadline is ${_formatDate(proj.deadline!)}.',
          entityType: 'project',
          entityId: proj.id,
          payload: {'projectId': proj.id, 'name': proj.name},
          urgency: isOverdue ? 'CRITICAL' : 'HIGH',
        ));
      }
    }

    return RuleEvaluationResult(
      ruleId: rule.id,
      isSuccess: true,
      itemsEvaluated: allProjects.length,
      itemsCreated: actions.length,
      proposedActions: actions,
      messages: ['Found ${actions.length} projects with urgent deadlines'],
    );
  }

  Future<RuleEvaluationResult> _evaluateWeeklySummary(AutomationRule rule) async {
    final aggregator = WeeklySummaryAggregator(db);
    final summary = await aggregator.aggregate();

    final List<ActionProposalItem> actions = [
      ActionProposalItem(
        actionType: 'WEEKLY_REPORT_READY',
        title: 'Weekly Standup Report Ready',
        description: 'Completed ${summary.tasksCompleted} tasks, solved ${summary.dsaProblemsSolved} DSA problems, net savings \$${summary.netSavings.toStringAsFixed(0)}.',
        entityType: 'weekly_summary',
        payload: {
          'tasksCompleted': summary.tasksCompleted,
          'dsaSolved': summary.dsaProblemsSolved,
          'netSavings': summary.netSavings,
        },
        urgency: 'LOW',
      ),
    ];

    return RuleEvaluationResult(
      ruleId: rule.id,
      isSuccess: true,
      itemsEvaluated: 1,
      itemsCreated: 1,
      proposedActions: actions,
      messages: ['Compiled factual weekly metrics report'],
    );
  }

  String _formatDate(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
