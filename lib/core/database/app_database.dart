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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? impl.connect());

  @override
  int get schemaVersion => 4;

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
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
      },
    );
  }

  // --- Profile Queries ---
  Future<UserProfile?> getProfile() => select(userProfiles).getSingleOrNull();
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
}

// Global Provider for AppDatabase instance
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
