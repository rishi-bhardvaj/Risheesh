import '../../../core/database/app_database.dart';
import 'ai_models.dart';

enum ContextFocus {
  dailyPlanning,
  career,
  work,
  dsa,
  learning,
  freelance,
  fitness,
  finance,
  general,
}

class AIContextBuilder {
  final AppDatabase _db;

  AIContextBuilder(this._db);

  Set<ContextFocus> detectIntents(String query) {
    final q = query.toLowerCase();
    final intents = <ContextFocus>{};

    if (q.contains('today') ||
        q.contains('focus') ||
        q.contains('plan') ||
        q.contains('schedule') ||
        q.contains('morning') ||
        q.contains('overview') ||
        q.contains('priority') ||
        q.contains('what should i')) {
      intents.add(ContextFocus.dailyPlanning);
    }

    if (q.contains('job') ||
        q.contains('career') ||
        q.contains('apply') ||
        q.contains('application') ||
        q.contains('interview') ||
        q.contains('recruiter') ||
        q.contains('resume') ||
        q.contains('match')) {
      intents.add(ContextFocus.career);
    }

    if (q.contains('work') ||
        q.contains('standup') ||
        q.contains('eod') ||
        q.contains('blocker') ||
        q.contains('meeting') ||
        q.contains('project') ||
        q.contains('task')) {
      intents.add(ContextFocus.work);
    }

    if (q.contains('dsa') ||
        q.contains('leetcode') ||
        q.contains('algorithm') ||
        q.contains('problem') ||
        q.contains('coding') ||
        q.contains('revise')) {
      intents.add(ContextFocus.dsa);
    }

    if (q.contains('learn') ||
        q.contains('skill') ||
        q.contains('course') ||
        q.contains('resource') ||
        q.contains('study') ||
        q.contains('book')) {
      intents.add(ContextFocus.learning);
    }

    if (q.contains('freelance') ||
        q.contains('client') ||
        q.contains('lead') ||
        q.contains('proposal') ||
        q.contains('gig') ||
        q.contains('invoice')) {
      intents.add(ContextFocus.freelance);
    }

    if (q.contains('fitness') ||
        q.contains('gym') ||
        q.contains('workout') ||
        q.contains('weight') ||
        q.contains('exercise') ||
        q.contains('health')) {
      intents.add(ContextFocus.fitness);
    }

    if (q.contains('finance') ||
        q.contains('money') ||
        q.contains('expense') ||
        q.contains('income') ||
        q.contains('saving') ||
        q.contains('budget') ||
        q.contains('spend')) {
      intents.add(ContextFocus.finance);
    }

    if (intents.isEmpty) {
      intents.add(ContextFocus.general);
    }

    return intents;
  }

  Future<ContextBuildResult> buildContext({
    required String query,
    int maxContextLength = 4096,
  }) async {
    final intents = detectIntents(query);
    final buffer = StringBuffer();
    final counts = <String, int>{};

    // 1. Career Profile
    final profile = await _db.getProfile();
    if (profile != null) {
      buffer.writeln('<database_context category="user_profile" is_untrusted_data="true">');
      buffer.writeln('Name: ${profile.name}');
      if (profile.preferredRoles != null && profile.preferredRoles!.isNotEmpty) {
        buffer.writeln('Target Roles: ${profile.preferredRoles}');
      }
      if (profile.currentRole != null && profile.currentRole!.isNotEmpty) {
        buffer.writeln('Current Role: ${profile.currentRole}');
      }
      if (profile.experienceYears > 0) {
        buffer.writeln('Experience: ${profile.experienceYears} yrs');
      }
      if (profile.skills != null && profile.skills!.isNotEmpty) {
        buffer.writeln('Primary Skills: ${profile.skills}');
      }
      if (profile.programmingLanguages != null && profile.programmingLanguages!.isNotEmpty) {
        buffer.writeln('Languages: ${profile.programmingLanguages}');
      }
      if (profile.frameworks != null && profile.frameworks!.isNotEmpty) {
        buffer.writeln('Frameworks: ${profile.frameworks}');
      }
      buffer.writeln('</database_context>\n');
      counts['profile'] = 1;
    }

    // Dynamic caps
    const maxTasks = 10;
    const maxJobs = 6;
    const maxDsaProblems = 8;
    const maxFreelance = 6;

    // 2. Tasks
    if (intents.contains(ContextFocus.dailyPlanning) ||
        intents.contains(ContextFocus.work) ||
        intents.contains(ContextFocus.general)) {
      final tasks = await _db.getAllTasks();
      final activeTasks = tasks.where((t) => t.status != 'completed').take(maxTasks).toList();
      if (activeTasks.isNotEmpty) {
        buffer.writeln('<database_context category="active_tasks" count="${activeTasks.length}" is_untrusted_data="true">');
        for (final t in activeTasks) {
          buffer.writeln('- [ID: ${t.id}] "${t.title}" | Category: ${t.category} | Priority: ${t.priority} | Status: ${t.status}${t.dueDate != null ? ' | Due: ${t.dueDate!.toIso8601String().substring(0, 10)}' : ''}');
        }
        buffer.writeln('</database_context>\n');
        counts['active_tasks'] = activeTasks.length;
      }
    }

    // 3. Career & Job Applications
    if (intents.contains(ContextFocus.career) || intents.contains(ContextFocus.dailyPlanning) || intents.contains(ContextFocus.general)) {
      final apps = await _db.getAllJobApplications();
      final activeApps = apps.where((a) => a.status != 'rejected' && a.status != 'withdrawn').take(maxJobs).toList();
      if (activeApps.isNotEmpty) {
        buffer.writeln('<database_context category="job_applications" count="${activeApps.length}" is_untrusted_data="true">');
        for (final a in activeApps) {
          buffer.writeln('- [App ID: ${a.id}] "${a.role}" at ${a.company} | Status: ${a.status}${a.followUpDate != null ? ' | FollowUp: ${a.followUpDate!.toIso8601String().substring(0, 10)}' : ''}${a.interviewDate != null ? ' | Interview: ${a.interviewDate!.toIso8601String().substring(0, 10)}' : ''}');
        }
        buffer.writeln('</database_context>\n');
        counts['job_applications'] = activeApps.length;
      }
    }

    // 4. Work Section
    if (intents.contains(ContextFocus.work) || intents.contains(ContextFocus.dailyPlanning) || intents.contains(ContextFocus.general)) {
      final projects = await _db.getAllProjects();
      final thingsToAsk = await _db.getAllThingsToAsk();
      final eodNotes = await _db.getAllEODNotes();

      final activeProjects = projects.where((p) => p.status != 'completed').toList();
      if (activeProjects.isNotEmpty) {
        buffer.writeln('<database_context category="active_projects" count="${activeProjects.length}" is_untrusted_data="true">');
        for (final p in activeProjects) {
          buffer.writeln('- [Project ID: ${p.id}] "${p.name}" (Status: ${p.status}, Progress: ${(p.progress * 100).toInt()}%)');
        }
        buffer.writeln('</database_context>\n');
        counts['projects'] = activeProjects.length;
      }

      final openQuestions = thingsToAsk.where((q) => q.status == 'open').take(5).toList();
      if (openQuestions.isNotEmpty) {
        buffer.writeln('<database_context category="things_to_ask_and_blockers" count="${openQuestions.length}" is_untrusted_data="true">');
        for (final q in openQuestions) {
          buffer.writeln('- [ID: ${q.id}] "${q.title}" (Priority: ${q.priority})');
        }
        buffer.writeln('</database_context>\n');
        counts['blockers'] = openQuestions.length;
      }

      if (eodNotes.isNotEmpty) {
        final recentEod = eodNotes.first;
        buffer.writeln('<database_context category="latest_eod_standup" date="${recentEod.date.toIso8601String().substring(0, 10)}" is_untrusted_data="true">');
        buffer.writeln('Completed: ${recentEod.completedWork}');
        if (recentEod.inProgressWork.isNotEmpty) buffer.writeln('In Progress: ${recentEod.inProgressWork}');
        if (recentEod.blockers != null && recentEod.blockers!.isNotEmpty) buffer.writeln('Blockers: ${recentEod.blockers}');
        buffer.writeln('</database_context>\n');
        counts['recent_eod'] = 1;
      }
    }

    // 5. DSA Context
    if (intents.contains(ContextFocus.dsa) || intents.contains(ContextFocus.dailyPlanning) || intents.contains(ContextFocus.general)) {
      final dsaProblems = await _db.getAllDSAProblems();
      final dsaToRevise = dsaProblems.where((p) => p.revisionDate != null || p.status != 'SOLVED').take(maxDsaProblems).toList();
      if (dsaToRevise.isNotEmpty) {
        buffer.writeln('<database_context category="dsa_problems" count="${dsaToRevise.length}" is_untrusted_data="true">');
        for (final p in dsaToRevise) {
          buffer.writeln('- [ID: ${p.id}] "${p.title}" | Platform: ${p.platform} | Topic: ${p.topic} | Diff: ${p.difficulty} | Status: ${p.status} | Attempts: ${p.attempts}${p.revisionDate != null ? ' | Revise: ${p.revisionDate!.toIso8601String().substring(0, 10)}' : ''}');
        }
        buffer.writeln('</database_context>\n');
        counts['dsa_problems'] = dsaToRevise.length;
      }
    }

    // 6. Learning Skills & Resources
    if (intents.contains(ContextFocus.learning) || intents.contains(ContextFocus.general)) {
      final skills = await _db.getAllSkills();
      final resources = await _db.getAllResources();
      final activeSkills = skills.take(6).toList();
      if (activeSkills.isNotEmpty) {
        buffer.writeln('<database_context category="learning_skills" count="${activeSkills.length}" is_untrusted_data="true">');
        for (final s in activeSkills) {
          buffer.writeln('- [ID: ${s.id}] "${s.name}" (Category: ${s.category}, Level: ${s.currentLevel} -> Target: ${s.targetLevel})');
        }
        buffer.writeln('</database_context>\n');
        counts['learning_skills'] = activeSkills.length;
      }

      final inProgressRes = resources.where((r) => r.status == 'in_progress' || r.status == 'to_read').take(5).toList();
      if (inProgressRes.isNotEmpty) {
        buffer.writeln('<database_context category="learning_resources" count="${inProgressRes.length}" is_untrusted_data="true">');
        for (final r in inProgressRes) {
          buffer.writeln('- [ID: ${r.id}] "${r.title}" (${r.type}, Status: ${r.status})');
        }
        buffer.writeln('</database_context>\n');
        counts['resources'] = inProgressRes.length;
      }
    }

    // 7. Freelance Context
    if (intents.contains(ContextFocus.freelance) || intents.contains(ContextFocus.dailyPlanning) || intents.contains(ContextFocus.general)) {
      final leads = await _db.getAllFreelanceLeads();
      final payments = await _db.getAllFreelancePayments();

      final activeLeads = leads.where((l) => l.status.toUpperCase() != 'WON' && l.status.toUpperCase() != 'LOST').take(maxFreelance).toList();
      if (activeLeads.isNotEmpty) {
        buffer.writeln('<database_context category="freelance_leads" count="${activeLeads.length}" is_untrusted_data="true">');
        for (final l in activeLeads) {
          buffer.writeln('- [ID: ${l.id}] "${l.title}" | Client: ${l.clientName ?? "N/A"} | Status: ${l.status} | Budget: ${l.currency} ${l.budget ?? 0}${l.followUpDate != null ? ' | FollowUp: ${l.followUpDate!.toIso8601String().substring(0, 10)}' : ''}');
        }
        buffer.writeln('</database_context>\n');
        counts['freelance_leads'] = activeLeads.length;
      }

      final pendingPayments = payments.where((p) => p.status.toUpperCase() != 'RECEIVED').toList();
      if (pendingPayments.isNotEmpty) {
        buffer.writeln('<database_context category="pending_freelance_payments" count="${pendingPayments.length}" is_untrusted_data="true">');
        for (final p in pendingPayments) {
          buffer.writeln('- [ID: ${p.id}] "${p.description ?? "Payment"}" | Amount: ${p.currency} ${p.amount} | Status: ${p.status} | Date: ${p.paymentDate.toIso8601String().substring(0, 10)}');
        }
        buffer.writeln('</database_context>\n');
        counts['pending_payments'] = pendingPayments.length;
      }
    }

    // 8. Fitness Context
    if (intents.contains(ContextFocus.fitness) || intents.contains(ContextFocus.general)) {
      final weights = await _db.getAllBodyWeights();
      final workouts = await _db.getAllWorkouts();

      if (weights.isNotEmpty) {
        final latestWeight = weights.first;
        buffer.writeln('<database_context category="latest_body_weight" date="${latestWeight.date.toIso8601String().substring(0, 10)}" is_untrusted_data="true">');
        buffer.writeln('Weight: ${latestWeight.weight} kg${latestWeight.note != null ? ' (${latestWeight.note})' : ''}');
        buffer.writeln('</database_context>\n');
        counts['latest_weight'] = 1;
      }

      if (workouts.isNotEmpty) {
        final recentWorkouts = workouts.take(3).toList();
        buffer.writeln('<database_context category="recent_workouts" count="${recentWorkouts.length}" is_untrusted_data="true">');
        for (final w in recentWorkouts) {
          buffer.writeln('- [ID: ${w.id}] "${w.name}" on ${w.date.toIso8601String().substring(0, 10)} (${w.duration ?? 0} mins)');
        }
        buffer.writeln('</database_context>\n');
        counts['recent_workouts'] = recentWorkouts.length;
      }
    }

    // 9. Finance Context
    if (intents.contains(ContextFocus.finance) || intents.contains(ContextFocus.general)) {
      final incomes = await _db.getAllIncomes();
      final expenses = await _db.getAllExpenses();

      final now = DateTime.now();
      final currentMonthExpenses = expenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
      final currentMonthIncomes = incomes.where((i) => i.date.year == now.year && i.date.month == now.month).toList();

      final totalExpense = currentMonthExpenses.fold<double>(0.0, (acc, e) => acc + e.amount);
      final totalIncome = currentMonthIncomes.fold<double>(0.0, (acc, i) => acc + i.amount);

      buffer.writeln('<database_context category="monthly_finance_summary" is_untrusted_data="true">');
      buffer.writeln('Current Month Income: \$${totalIncome.toStringAsFixed(2)}');
      buffer.writeln('Current Month Expense: \$${totalExpense.toStringAsFixed(2)}');
      buffer.writeln('Net Savings: \$${(totalIncome - totalExpense).toStringAsFixed(2)}');
      buffer.writeln('</database_context>\n');
      counts['finance_records'] = currentMonthExpenses.length + currentMonthIncomes.length;
    }

    String resultText = buffer.toString();
    if (resultText.length > maxContextLength) {
      resultText = resultText.substring(0, maxContextLength);
    }

    // Rough estimate: ~4 chars per token
    final tokenEstimate = (resultText.length / 4).ceil();

    return ContextBuildResult(
      systemContext: resultText,
      recordCounts: counts,
      tokenEstimate: tokenEstimate,
    );
  }
}
