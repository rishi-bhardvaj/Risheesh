import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/features/career/domain/job_match_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    // In-memory database for fast, isolated unit testing
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Career Module & Profile Tests', () {
    test('Career User Profile full fields upsert and retrieval', () async {
      final now = DateTime.now();
      final companion = UserProfilesCompanion(
        id: const Value('user-1'),
        name: const Value('Risheesh Upadhyay'),
        currentRole: const Value('Lead Backend Architect'),
        experienceYears: const Value(4.0),
        skills: const Value('Microservices, System Design, REST APIs, CI/CD'),
        programmingLanguages: const Value('Java, Dart, TypeScript, SQL'),
        frameworks: const Value('Spring Boot, Flutter, PostgreSQL, Docker, AWS'),
        preferredRoles: const Value('Senior Backend Engineer, Staff Engineer'),
        preferredLocations: const Value('Bengaluru, Hyderabad'),
        remotePreference: const Value('remote'),
        expectedSalary: const Value('₹35-45 LPA'),
        preferredEmploymentType: const Value('Full-time'),
        noticePeriod: const Value('30 days'),
        education: const Value('B.Tech in Computer Science'),
        resumePreferences: const Value('Focus on distributed architectures and latency reduction'),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      await db.upsertProfile(companion);
      final profile = await db.getProfile();

      expect(profile != null, true);
      expect(profile!.name, 'Risheesh Upadhyay');
      expect(profile.currentRole, 'Lead Backend Architect');
      expect(profile.experienceYears, 4.0);
      expect(profile.programmingLanguages, 'Java, Dart, TypeScript, SQL');
      expect(profile.frameworks, 'Spring Boot, Flutter, PostgreSQL, Docker, AWS');
      expect(profile.remotePreference, 'remote');
      expect(profile.noticePeriod, '30 days');
    });

    test('Job management, bookmarks, and notes lifecycle', () async {
      final now = DateTime.now();
      final jobComp = JobsCompanion(
        id: const Value('job-101'),
        title: const Value('Senior Java Engineer'),
        company: const Value('Google'),
        location: const Value('Bengaluru'),
        salary: const Value('₹45 LPA'),
        employmentType: const Value('Full-time'),
        experienceRequirement: const Value('3+ years'),
        skills: const Value('Java, Spring Boot, Distributed Systems, Kubernetes'),
        url: const Value('https://careers.google.com/jobs/101'),
        source: const Value('LinkedIn'),
        description: const Value('Design and build highly scalable distributed storage engines.'),
        notes: const Value('Referral through alumni network'),
        isSaved: const Value(false),
        postedDate: Value(now),
        discoveredAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      await db.insertJob(jobComp);
      var allJobs = await db.getAllJobs();
      expect(allJobs.length, 1);
      expect(allJobs.first.company, 'Google');
      expect(allJobs.first.isSaved, false);

      // Toggle Bookmark
      await db.toggleJobSaved('job-101', true);
      var updated = await db.getJobById('job-101');
      expect(updated!.isSaved, true);

      // Query saved jobs
      final savedJobs = await (db.select(db.jobs)..where((j) => j.isSaved.equals(true))).get();
      expect(savedJobs.length, 1);
      expect(savedJobs.first.title, 'Senior Java Engineer');
    });

    test('Resume Vault management and primary toggle', () async {
      final now = DateTime.now();
      final resume1 = ResumesCompanion(
        id: const Value('res-1'),
        name: const Value('Backend Java Resume'),
        version: const Value('v3.0'),
        targetRole: const Value('Senior Java Backend'),
        filePath: const Value('/data/user/0/career_os/resumes/res1.pdf'),
        fileName: const Value('res1.pdf'),
        notes: const Value('Highlights Spring Boot and Kafka'),
        isPrimary: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      final resume2 = ResumesCompanion(
        id: const Value('res-2'),
        name: const Value('Full Stack Flutter Resume'),
        version: const Value('v2.1'),
        targetRole: const Value('Full Stack Engineer'),
        filePath: const Value('/data/user/0/career_os/resumes/res2.pdf'),
        fileName: const Value('res2.pdf'),
        isPrimary: const Value(false),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      await db.insertResume(resume1);
      await db.insertResume(resume2);

      var resumes = await db.getAllResumes();
      expect(resumes.length, 2);

      // Set resume 2 as primary (must atomically demote resume 1)
      await db.setPrimaryResume('res-2');

      final r1 = await db.getResumeById('res-1');
      final r2 = await db.getResumeById('res-2');
      expect(r1!.isPrimary, false);
      expect(r2!.isPrimary, true);
    });

    test('Job Application linked with Job and Resume, and duplicate check', () async {
      final now = DateTime.now();

      // Create Job
      await db.insertJob(JobsCompanion(
        id: const Value('job-301'),
        title: const Value('Staff Systems Engineer'),
        company: const Value('Uber'),
        location: const Value('Hyderabad'),
        salary: const Value('₹50 LPA'),
        employmentType: const Value('Full-time'),
        url: const Value('https://uber.com/careers/301'),
        source: const Value('Direct'),
        discoveredAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      // Create Resume
      await db.insertResume(ResumesCompanion(
        id: const Value('res-301'),
        name: const Value('Infrastructure Resume'),
        version: const Value('v1.0'),
        filePath: const Value('/data/res.pdf'),
        fileName: const Value('res.pdf'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      // Create Application linked to Job & Resume
      final appComp = JobApplicationsCompanion(
        id: const Value('app-501'),
        jobId: const Value('job-301'),
        company: const Value('Uber'),
        role: const Value('Staff Systems Engineer'),
        salary: const Value('₹50 LPA'),
        location: const Value('Hyderabad'),
        status: const Value('screening'),
        appliedAt: Value(now),
        followUpDate: Value(now.add(const Duration(days: 3))),
        interviewDate: Value(now.add(const Duration(days: 7))),
        interviewStage: const Value('System Design Round 1'),
        recruiterName: const Value('David Miller'),
        recruiterContact: const Value('david.miller@uber.com'),
        resumeId: const Value('res-301'),
        resumeUsed: const Value('Infrastructure Resume (v1.0)'),
        nextAction: const Value('Revise consistent hashing and distributed caches'),
        notes: const Value('Recruiter contacted on LinkedIn'),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      await db.insertApplication(appComp);
      final apps = await db.getAllApplications();
      expect(apps.length, 1);
      expect(apps.first.company, 'Uber');
      expect(apps.first.status, 'screening');

      // Duplicate Check Query
      final existingApp = await db.getApplicationByJobId('job-301');
      expect(existingApp != null, true);
      expect(existingApp!.company, 'Uber');
      expect(existingApp.recruiterName, 'David Miller');
      expect(existingApp.resumeId, 'res-301');

      // Update Application status
      await db.updateApplication(appComp.copyWith(
        status: const Value('interview'),
        updatedAt: Value(DateTime.now()),
      ));

      final updatedApp = await db.getApplicationById('app-501');
      expect(updatedApp!.status, 'interview');
    });

    test('JobMatchService calculates transparent match percentage and factors', () {
      final profile = UserProfile(
        id: 'u1',
        name: 'Risheesh',
        currentRole: 'Backend Engineer',
        experienceYears: 3.5,
        skills: 'Java, Spring Boot, PostgreSQL, Docker',
        programmingLanguages: 'Java, SQL',
        frameworks: 'Spring Boot, Docker',
        preferredRoles: 'Backend Engineer, Software Engineer',
        preferredLocations: 'Bengaluru',
        remotePreference: 'remote',
        expectedSalary: '30 LPA',
        preferredEmploymentType: 'Full-time',
        noticePeriod: '30 days',
        education: 'B.Tech',
        resumePreferences: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final matchingJob = Job(
        id: 'j1',
        title: 'Senior Backend Engineer',
        company: 'Stripe',
        location: 'Remote',
        salary: '₹35 LPA',
        employmentType: 'Full-time',
        experienceRequirement: '3+ years',
        url: null,
        source: 'LinkedIn',
        description: 'Building payment microservices using Java and Spring Boot',
        skills: 'Java, Spring Boot, PostgreSQL, AWS',
        postedDate: null,
        discoveredAt: DateTime.now(),
        isSaved: true,
        notes: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final matchResult = JobMatchService.calculateMatch(job: matchingJob, profile: profile);

      expect(matchResult.hasSufficientData, true);
      expect(matchResult.matchPercentage >= 70, true);
      expect(matchResult.matchingFactors.any((f) => f.toLowerCase().contains('role match')), true);
      expect(matchResult.matchingFactors.any((f) => f.toLowerCase().contains('java')), true);
      expect(matchResult.gapFactors.any((f) => f.toLowerCase().contains('aws')), true);
    });
  });

  group('Phase 3 Work Module Database & Logic Tests', () {
    test('Work Tasks with category, project linking, notes, and lifecycle', () async {
      final now = DateTime.now();

      // Create a Project first
      final projComp = ProjectsCompanion(
        id: const Value('proj-work-1'),
        name: const Value('Career OS App'),
        description: const Value('Personal command center app in Flutter'),
        status: const Value('in_progress'),
        progress: const Value(0.8),
        techStack: const Value('Flutter, Riverpod, Drift SQLite'),
        deadline: Value(now.add(const Duration(days: 14))),
        notes: const Value('Release debug APK to GitHub releases'),
        createdAt: Value(now),
        updatedAt: Value(now),
      );
      await db.insertProject(projComp);

      // Create Work Task linked to project
      final task1 = TasksCompanion(
        id: const Value('task-w-1'),
        title: const Value('Implement Work module SQLite tables'),
        description: const Value('Add ThingsToAsks and WorkNotes tables with schema v3'),
        priority: const Value('high'),
        status: const Value('in_progress'),
        category: const Value('work'),
        projectId: const Value('proj-work-1'),
        dueDate: Value(now),
        notes: const Value('Checked migration logic for existing databases'),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      // Create Personal Task (standalone)
      final task2 = TasksCompanion(
        id: const Value('task-p-1'),
        title: const Value('Renew health insurance policy'),
        priority: const Value('medium'),
        status: const Value('todo'),
        category: const Value('personal'),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      await db.insertTask(task1);
      await db.insertTask(task2);

      final allTasks = await db.getAllTasks();
      expect(allTasks.length, 2);

      // Verify category filtering
      final workTasks = allTasks.where((t) => t.category == 'work').toList();
      final personalTasks = allTasks.where((t) => t.category == 'personal').toList();
      expect(workTasks.length, 1);
      expect(personalTasks.length, 1);
      expect(workTasks.first.projectId, 'proj-work-1');
      expect(workTasks.first.notes, 'Checked migration logic for existing databases');

      // Verify project tasks querying
      final projTasks = await db.getTasksByProject('proj-work-1');
      expect(projTasks.length, 1);
      expect(projTasks.first.id, 'task-w-1');

      // Complete task
      await db.updateTask(task1.copyWith(
        status: const Value('completed'),
        updatedAt: Value(DateTime.now()),
      ));
      final completed = await db.getTaskById('task-w-1');
      expect(completed!.status, 'completed');
    });

    test('EOD Notes Standup single-per-day upsert and querying', () async {
      final today = DateTime.now();

      final eod1 = EODNotesCompanion(
        id: const Value('eod-1'),
        date: Value(today),
        completedWork: const Value('• Finished Drift schema migration\n• Updated router deep links'),
        inProgressWork: const Value('• Writing widget integration tests'),
        blockers: const Value('None'),
        tomorrowPlan: const Value('• Build APK and verify release assets'),
        notes: const Value('Sprint planning tomorrow 10 AM'),
        createdAt: Value(today),
        updatedAt: Value(today),
      );

      await db.insertEODNote(eod1);

      // Retrieve for date
      final retrieved = await db.getEODNoteForDate(today);
      expect(retrieved != null, true);
      expect(retrieved!.completedWork.contains('Finished Drift schema'), true);
      expect(retrieved.notes, 'Sprint planning tomorrow 10 AM');

      // Update today's note with new blockers
      final updatedComp = EODNotesCompanion(
        id: Value(retrieved.id),
        date: Value(retrieved.date),
        completedWork: Value(retrieved.completedWork),
        inProgressWork: const Value('• Completed widget tests!'),
        blockers: const Value('Waiting on signing keystore credentials'),
        tomorrowPlan: Value(retrieved.tomorrowPlan),
        notes: Value(retrieved.notes),
        createdAt: Value(retrieved.createdAt),
        updatedAt: Value(DateTime.now()),
      );
      await db.updateEODNote(updatedComp);

      final afterUpdate = await db.getEODNoteById('eod-1');
      expect(afterUpdate!.inProgressWork, '• Completed widget tests!');
      expect(afterUpdate.blockers, 'Waiting on signing keystore credentials');

      // All notes count
      final allEODs = await db.getAllEODNotes();
      expect(allEODs.length, 1);
    });

    test('Things to Ask / Blockers lifecycle and resolve toggle', () async {
      final now = DateTime.now();

      final question1 = ThingsToAsksCompanion(
        id: const Value('q-1'),
        title: const Value('Ask lead about Redis caching TTL policy'),
        description: const Value('Currently default is 24h, should we reduce for user profiles?'),
        priority: const Value('high'),
        status: const Value('open'),
        createdAt: Value(now),
      );

      final question2 = ThingsToAsksCompanion(
        id: const Value('q-2'),
        title: const Value('Clarify Docker compose staging port collision'),
        priority: const Value('medium'),
        status: const Value('open'),
        createdAt: Value(now),
      );

      await db.insertThingToAsk(question1);
      await db.insertThingToAsk(question2);

      var allQuestions = await db.getAllThingsToAsk();
      expect(allQuestions.length, 2);

      // Resolve question 1
      await db.toggleThingToAskStatus('q-1', true);

      final q1 = await (db.select(db.thingsToAsks)..where((q) => q.id.equals('q-1'))).getSingle();
      expect(q1.status, 'resolved');
      expect(q1.completedAt != null, true);

      // Delete question 2
      await db.deleteThingToAsk('q-2');
      allQuestions = await db.getAllThingsToAsk();
      expect(allQuestions.length, 1);
      expect(allQuestions.first.id, 'q-1');
    });

    test('Work Notes and Meeting Notes management with action items', () async {
      final now = DateTime.now();

      await db.insertProject(ProjectsCompanion(
        id: const Value('proj-work-1'),
        name: const Value('Event Ingestion Pipeline'),
        status: const Value('inProgress'),
        progress: const Value(0.4),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final meetingNote = WorkNotesCompanion(
        id: const Value('note-1'),
        title: const Value('Architecture Sync - Event Ingestion'),
        content: const Value('Decided to proceed with Kafka partitioning by tenant ID for strict order.'),
        noteType: const Value('meeting'),
        projectId: const Value('proj-work-1'),
        meetingDate: Value(now),
        participants: const Value('Alice, Bob, Risheesh'),
        actionItems: const Value('• Write RFC document\n• Benchmark tenant partition throughput\n• Review PR #302'),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      final techNote = WorkNotesCompanion(
        id: const Value('note-2'),
        title: const Value('PostgreSQL Indexing Runbook'),
        content: const Value('Use partial indexes with WHERE deleted_at IS NULL for fast soft-delete lookups.'),
        noteType: const Value('instruction'),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      await db.insertWorkNote(meetingNote);
      await db.insertWorkNote(techNote);

      final allNotes = await db.getAllWorkNotes();
      expect(allNotes.length, 2);

      final retrievedMeeting = await db.getWorkNoteById('note-1');
      expect(retrievedMeeting != null, true);
      expect(retrievedMeeting!.noteType, 'meeting');
      expect(retrievedMeeting.participants, 'Alice, Bob, Risheesh');
      expect(retrievedMeeting.actionItems!.contains('Benchmark tenant partition'), true);

      // Update technical note
      await db.updateWorkNote(techNote.copyWith(
        content: const Value('Updated runbook with BRIN index benchmarks for timeseries.'),
        updatedAt: Value(DateTime.now()),
      ));

      final updatedTech = await db.getWorkNoteById('note-2');
      expect(updatedTech!.content.contains('BRIN index'), true);

      // Delete note
      await db.deleteWorkNote('note-2');
      final remaining = await db.getAllWorkNotes();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'note-1');
    });
  });
}
