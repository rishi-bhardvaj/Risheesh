import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../domain/job_match_service.dart';
import '../domain/job_search_criteria_builder.dart';
import '../domain/resume_profile_models.dart';
import '../services/live_job_discovery_service.dart';

// --- Profile Providers ---
final careerProfileProvider = StreamProvider<UserProfile?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchProfile();
});

// --- Job Filter and Sort State Models ---
enum JobSortOption {
  newest('Newest First'),
  oldest('Oldest First'),
  company('Company (A-Z)'),
  title('Job Title (A-Z)');

  final String label;
  const JobSortOption(this.label);
}

class JobFilterState {
  final bool savedOnly;
  final String? employmentType; // 'Full-time', 'Contract', etc.
  final String? remotePreference; // 'remote', 'hybrid', 'on-site'
  final String? source;
  final String? location;

  const JobFilterState({
    this.savedOnly = false,
    this.employmentType,
    this.remotePreference,
    this.source,
    this.location,
  });

  JobFilterState copyWith({
    bool? savedOnly,
    String? employmentType,
    String? remotePreference,
    String? source,
    String? location,
    bool clearEmploymentType = false,
    bool clearRemotePreference = false,
    bool clearSource = false,
    bool clearLocation = false,
  }) {
    return JobFilterState(
      savedOnly: savedOnly ?? this.savedOnly,
      employmentType: clearEmploymentType ? null : (employmentType ?? this.employmentType),
      remotePreference: clearRemotePreference ? null : (remotePreference ?? this.remotePreference),
      source: clearSource ? null : (source ?? this.source),
      location: clearLocation ? null : (location ?? this.location),
    );
  }

  bool get hasActiveFilters =>
      savedOnly ||
      employmentType != null ||
      remotePreference != null ||
      source != null ||
      (location != null && location!.isNotEmpty);
}

final jobSearchQueryProvider = StateProvider<String>((ref) => '');
final jobFilterProvider = StateProvider<JobFilterState>((ref) => const JobFilterState());
final jobSortProvider = StateProvider<JobSortOption>((ref) => JobSortOption.newest);

// --- Jobs Stream ---
final allJobsProvider = StreamProvider<List<Job>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllJobs();
});

final savedJobsProvider = StreamProvider<List<Job>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchSavedJobs();
});

// --- Filtered and Sorted Jobs ---
final filteredJobsProvider = Provider<List<Job>>((ref) {
  final jobsAsync = ref.watch(allJobsProvider);
  final query = ref.watch(jobSearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(jobFilterProvider);
  final sort = ref.watch(jobSortProvider);

  return jobsAsync.maybeWhen(
    data: (jobs) {
      var list = List<Job>.from(jobs);

      // 1. Search Query
      if (query.isNotEmpty) {
        list = list.where((j) {
          final title = j.title.toLowerCase();
          final company = j.company.toLowerCase();
          final location = (j.location ?? '').toLowerCase();
          final skills = (j.skills ?? '').toLowerCase();
          final desc = (j.description ?? '').toLowerCase();
          return title.contains(query) ||
              company.contains(query) ||
              location.contains(query) ||
              skills.contains(query) ||
              desc.contains(query);
        }).toList();
      }

      // 2. Saved Only Filter
      if (filter.savedOnly) {
        list = list.where((j) => j.isSaved).toList();
      }

      // 3. Employment Type Filter
      if (filter.employmentType != null && filter.employmentType!.isNotEmpty) {
        list = list.where((j) => (j.employmentType ?? '').toLowerCase().contains(filter.employmentType!.toLowerCase())).toList();
      }

      // 4. Remote Preference Filter
      if (filter.remotePreference != null && filter.remotePreference!.isNotEmpty) {
        final pref = filter.remotePreference!.toLowerCase();
        list = list.where((j) {
          final loc = (j.location ?? '').toLowerCase();
          final emp = (j.employmentType ?? '').toLowerCase();
          if (pref == 'remote') return loc.contains('remote') || emp.contains('remote');
          if (pref == 'hybrid') return loc.contains('hybrid') || emp.contains('hybrid');
          if (pref == 'on-site' || pref == 'onsite') return !loc.contains('remote') && !emp.contains('remote');
          return true;
        }).toList();
      }

      // 5. Source Filter
      if (filter.source != null && filter.source!.isNotEmpty) {
        list = list.where((j) => (j.source ?? '').toLowerCase().contains(filter.source!.toLowerCase())).toList();
      }

      // 6. Location Filter
      if (filter.location != null && filter.location!.isNotEmpty) {
        list = list.where((j) => (j.location ?? '').toLowerCase().contains(filter.location!.toLowerCase())).toList();
      }

      // 7. Sorting
      switch (sort) {
        case JobSortOption.newest:
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case JobSortOption.oldest:
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case JobSortOption.company:
          list.sort((a, b) => a.company.toLowerCase().compareTo(b.company.toLowerCase()));
          break;
        case JobSortOption.title:
          list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          break;
      }

      return list;
    },
    orElse: () => [],
  );
});

// Single Job Provider
final jobByIdProvider = StreamProvider.family<Job?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.jobs)..where((j) => j.id.equals(id))).watchSingleOrNull();
});

// Job Match Provider for a given Job
final jobMatchProvider = Provider.family<JobMatchResult, Job>((ref, job) {
  final profile = ref.watch(careerProfileProvider).valueOrNull;
  return JobMatchService.calculateMatch(job: job, profile: profile);
});

// Existing Application for a Job
final jobApplicationByJobIdProvider = StreamProvider.family<JobApplication?, String>((ref, jobId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.jobApplications)..where((a) => a.jobId.equals(jobId))).watchSingleOrNull();
});

// --- Application Filter & Sort State Models ---
enum ApplicationSortOption {
  recentlyUpdated('Recently Updated'),
  appliedDate('Applied Date'),
  followUpDate('Follow-up Date'),
  company('Company (A-Z)'),
  status('Status');

  final String label;
  const ApplicationSortOption(this.label);
}

final applicationSearchQueryProvider = StateProvider<String>((ref) => '');
final applicationFilterStatusProvider = StateProvider<String>((ref) => 'all'); // 'all', or ApplicationStatus name
final applicationSortProvider = StateProvider<ApplicationSortOption>((ref) => ApplicationSortOption.recentlyUpdated);

// --- Applications Stream ---
final allApplicationsProvider = StreamProvider<List<JobApplication>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllApplications();
});

final applicationByIdProvider = StreamProvider.family<JobApplication?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.jobApplications)..where((a) => a.id.equals(id))).watchSingleOrNull();
});

// --- Filtered and Sorted Applications ---
final filteredApplicationsProvider = Provider<List<JobApplication>>((ref) {
  final appsAsync = ref.watch(allApplicationsProvider);
  final query = ref.watch(applicationSearchQueryProvider).trim().toLowerCase();
  final statusFilter = ref.watch(applicationFilterStatusProvider).toLowerCase();
  final sort = ref.watch(applicationSortProvider);

  return appsAsync.maybeWhen(
    data: (apps) {
      var list = List<JobApplication>.from(apps);

      // 1. Status filter
      if (statusFilter != 'all') {
        list = list.where((a) => a.status.toLowerCase() == statusFilter).toList();
      }

      // 2. Search query (company, role, recruiter, notes)
      if (query.isNotEmpty) {
        list = list.where((a) {
          final comp = a.company.toLowerCase();
          final role = a.role.toLowerCase();
          final rec = (a.recruiterName ?? '').toLowerCase();
          final notes = (a.notes ?? '').toLowerCase();
          return comp.contains(query) || role.contains(query) || rec.contains(query) || notes.contains(query);
        }).toList();
      }

      // 3. Sorting
      switch (sort) {
        case ApplicationSortOption.recentlyUpdated:
          list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          break;
        case ApplicationSortOption.appliedDate:
          list.sort((a, b) {
            final dateA = a.appliedAt ?? a.createdAt;
            final dateB = b.appliedAt ?? b.createdAt;
            return dateB.compareTo(dateA);
          });
          break;
        case ApplicationSortOption.followUpDate:
          list.sort((a, b) {
            if (a.followUpDate == null && b.followUpDate == null) return 0;
            if (a.followUpDate == null) return 1;
            if (b.followUpDate == null) return -1;
            return a.followUpDate!.compareTo(b.followUpDate!);
          });
          break;
        case ApplicationSortOption.company:
          list.sort((a, b) => a.company.toLowerCase().compareTo(b.company.toLowerCase()));
          break;
        case ApplicationSortOption.status:
          list.sort((a, b) => a.status.compareTo(b.status));
          break;
      }

      return list;
    },
    orElse: () => [],
  );
});

// --- Follow-ups Due ---
final followUpApplicationsProvider = Provider<List<JobApplication>>((ref) {
  final appsAsync = ref.watch(allApplicationsProvider);
  return appsAsync.maybeWhen(
    data: (apps) => apps.where((a) => a.followUpDate != null).toList(),
    orElse: () => [],
  );
});

final followUpsDueTodayProvider = Provider<List<JobApplication>>((ref) {
  final followUps = ref.watch(followUpApplicationsProvider);
  final now = DateTime.now();
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return followUps.where((a) {
    if (a.followUpDate == null) return false;
    // Due today or overdue
    return a.followUpDate!.isBefore(endOfToday) &&
        a.status.toLowerCase() != 'rejected' &&
        a.status.toLowerCase() != 'withdrawn' &&
        a.status.toLowerCase() != 'offer';
  }).toList();
});

final upcomingFollowUpsProvider = Provider<List<JobApplication>>((ref) {
  final followUps = ref.watch(followUpApplicationsProvider);
  final now = DateTime.now();
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return followUps.where((a) {
    if (a.followUpDate == null) return false;
    return a.followUpDate!.isAfter(endOfToday) &&
        a.status.toLowerCase() != 'rejected' &&
        a.status.toLowerCase() != 'withdrawn';
  }).toList()
    ..sort((a, b) => a.followUpDate!.compareTo(b.followUpDate!));
});

// --- Resumes Providers ---
final allResumesProvider = StreamProvider<List<Resume>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllResumes();
});

final primaryResumeProvider = Provider<Resume?>((ref) {
  final resumesAsync = ref.watch(allResumesProvider);
  return resumesAsync.maybeWhen(
    data: (resumes) {
      if (resumes.isEmpty) return null;
      return resumes.firstWhere((r) => r.isPrimary, orElse: () => resumes.first);
    },
    orElse: () => null,
  );
});

final resumeByIdProvider = StreamProvider.family<Resume?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.resumes)..where((r) => r.id.equals(id))).watchSingleOrNull();
});

// --- Saved Searches Providers ---
final allSavedSearchesProvider = StreamProvider<List<SavedSearch>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSavedSearches();
});

// --- Career Snapshot (Home dashboard summary metrics) ---
class CareerSnapshotData {
  final int savedJobsCount;
  final int totalApplications;
  final int activeApplicationsCount;
  final int interviewsCount;
  final int offersCount;
  final int followUpsDueCount;

  const CareerSnapshotData({
    required this.savedJobsCount,
    required this.totalApplications,
    required this.activeApplicationsCount,
    required this.interviewsCount,
    required this.offersCount,
    required this.followUpsDueCount,
  });
}

final careerSnapshotProvider = Provider<CareerSnapshotData>((ref) {
  final jobs = ref.watch(allJobsProvider).valueOrNull ?? [];
  final apps = ref.watch(allApplicationsProvider).valueOrNull ?? [];
  final followUpsDue = ref.watch(followUpsDueTodayProvider);

  final savedJobs = jobs.where((j) => j.isSaved).length;
  final activeApps = apps.where((a) {
    final s = a.status.toLowerCase();
    return s != 'rejected' && s != 'withdrawn' && s != 'offer';
  }).length;
  final interviews = apps.where((a) {
    final s = a.status.toLowerCase();
    return s == 'interview' || s == 'technical' || s == 'hr' || s == 'screening';
  }).length;
  final offers = apps.where((a) => a.status.toLowerCase() == 'offer').length;

  return CareerSnapshotData(
    savedJobsCount: savedJobs,
    totalApplications: apps.length,
    activeApplicationsCount: activeApps,
    interviewsCount: interviews,
    offersCount: offers,
    followUpsDueCount: followUpsDue.length,
  );
});

// Career Repository / Actions
class CareerRepository {
  final AppDatabase db;
  static const _uuid = Uuid();

  CareerRepository(this.db);

  Future<void> addJob({
    required String title,
    required String company,
    String? location,
    String? salary,
    String? employmentType,
    String? experienceRequirement,
    String? url,
    String? source,
    String? description,
    String? skills,
    DateTime? postedDate,
    bool isSaved = false,
    String? notes,
  }) async {
    final now = DateTime.now();
    final companion = JobsCompanion(
      id: Value(_uuid.v4()),
      title: Value(title.trim()),
      company: Value(company.trim()),
      location: Value(location?.trim().isEmpty == true ? null : location?.trim()),
      salary: Value(salary?.trim().isEmpty == true ? null : salary?.trim()),
      employmentType: Value(employmentType?.trim().isEmpty == true ? null : employmentType?.trim()),
      experienceRequirement: Value(experienceRequirement?.trim().isEmpty == true ? null : experienceRequirement?.trim()),
      url: Value(url?.trim().isEmpty == true ? null : url?.trim()),
      source: Value(source?.trim().isEmpty == true ? 'Manual' : source?.trim()),
      description: Value(description?.trim().isEmpty == true ? null : description?.trim()),
      skills: Value(skills?.trim().isEmpty == true ? null : skills?.trim()),
      postedDate: Value(postedDate),
      discoveredAt: Value(now),
      isSaved: Value(isSaved),
      notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await db.insertJob(companion);
  }

  Future<void> updateJob({
    required String id,
    required String title,
    required String company,
    String? location,
    String? salary,
    String? employmentType,
    String? experienceRequirement,
    String? url,
    String? source,
    String? description,
    String? skills,
    DateTime? postedDate,
    bool? isSaved,
    String? notes,
  }) async {
    final companion = JobsCompanion(
      id: Value(id),
      title: Value(title.trim()),
      company: Value(company.trim()),
      location: Value(location?.trim().isEmpty == true ? null : location?.trim()),
      salary: Value(salary?.trim().isEmpty == true ? null : salary?.trim()),
      employmentType: Value(employmentType?.trim().isEmpty == true ? null : employmentType?.trim()),
      experienceRequirement: Value(experienceRequirement?.trim().isEmpty == true ? null : experienceRequirement?.trim()),
      url: Value(url?.trim().isEmpty == true ? null : url?.trim()),
      source: Value(source?.trim().isEmpty == true ? 'Manual' : source?.trim()),
      description: Value(description?.trim().isEmpty == true ? null : description?.trim()),
      skills: Value(skills?.trim().isEmpty == true ? null : skills?.trim()),
      postedDate: Value(postedDate),
      isSaved: isSaved != null ? Value(isSaved) : const Value.absent(),
      notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      updatedAt: Value(DateTime.now()),
    );
    await db.updateJob(companion);
  }

  Future<void> deleteJob(String id) => db.deleteJob(id);

  Future<void> toggleJobSaved(String id, bool isSaved) => db.toggleJobSaved(id, isSaved);

  Future<void> convertJobToApplication({
    required Job job,
    required ApplicationStatus status,
    DateTime? appliedAt,
    DateTime? followUpDate,
    DateTime? interviewDate,
    String? interviewStage,
    String? recruiterName,
    String? recruiterContact,
    String? resumeId,
    String? resumeUsed,
    String? nextAction,
    String? notes,
  }) async {
    final now = DateTime.now();
    final companion = JobApplicationsCompanion(
      id: Value(_uuid.v4()),
      jobId: Value(job.id),
      company: Value(job.company),
      role: Value(job.title),
      salary: Value(job.salary),
      location: Value(job.location),
      url: Value(job.url),
      status: Value(status.name),
      appliedAt: Value(appliedAt ?? now),
      followUpDate: Value(followUpDate),
      interviewDate: Value(interviewDate),
      interviewStage: Value(interviewStage?.trim().isEmpty == true ? null : interviewStage?.trim()),
      recruiterName: Value(recruiterName?.trim().isEmpty == true ? null : recruiterName?.trim()),
      recruiterContact: Value(recruiterContact?.trim().isEmpty == true ? null : recruiterContact?.trim()),
      resumeId: Value(resumeId),
      resumeUsed: Value(resumeUsed?.trim().isEmpty == true ? null : resumeUsed?.trim()),
      nextAction: Value(nextAction?.trim().isEmpty == true ? null : nextAction?.trim()),
      notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await db.insertApplication(companion);
  }

  Future<void> addDirectApplication({
    required String company,
    required String role,
    String? jobId,
    String? location,
    String? salary,
    String? url,
    required ApplicationStatus status,
    DateTime? appliedAt,
    DateTime? followUpDate,
    DateTime? interviewDate,
    String? interviewStage,
    String? recruiterName,
    String? recruiterContact,
    String? resumeId,
    String? resumeUsed,
    String? nextAction,
    String? notes,
  }) async {
    final now = DateTime.now();
    final companion = JobApplicationsCompanion(
      id: Value(_uuid.v4()),
      jobId: Value(jobId),
      company: Value(company.trim()),
      role: Value(role.trim()),
      salary: Value(salary?.trim().isEmpty == true ? null : salary?.trim()),
      location: Value(location?.trim().isEmpty == true ? null : location?.trim()),
      url: Value(url?.trim().isEmpty == true ? null : url?.trim()),
      status: Value(status.name),
      appliedAt: Value(appliedAt ?? now),
      followUpDate: Value(followUpDate),
      interviewDate: Value(interviewDate),
      interviewStage: Value(interviewStage?.trim().isEmpty == true ? null : interviewStage?.trim()),
      recruiterName: Value(recruiterName?.trim().isEmpty == true ? null : recruiterName?.trim()),
      recruiterContact: Value(recruiterContact?.trim().isEmpty == true ? null : recruiterContact?.trim()),
      resumeId: Value(resumeId),
      resumeUsed: Value(resumeUsed?.trim().isEmpty == true ? null : resumeUsed?.trim()),
      nextAction: Value(nextAction?.trim().isEmpty == true ? null : nextAction?.trim()),
      notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await db.insertApplication(companion);
  }

  Future<void> updateApplication({
    required String id,
    required String company,
    required String role,
    String? jobId,
    String? location,
    String? salary,
    String? url,
    required ApplicationStatus status,
    DateTime? appliedAt,
    DateTime? followUpDate,
    DateTime? interviewDate,
    String? interviewStage,
    String? recruiterName,
    String? recruiterContact,
    String? resumeId,
    String? resumeUsed,
    String? nextAction,
    String? notes,
  }) async {
    final companion = JobApplicationsCompanion(
      id: Value(id),
      jobId: Value(jobId),
      company: Value(company.trim()),
      role: Value(role.trim()),
      salary: Value(salary?.trim().isEmpty == true ? null : salary?.trim()),
      location: Value(location?.trim().isEmpty == true ? null : location?.trim()),
      url: Value(url?.trim().isEmpty == true ? null : url?.trim()),
      status: Value(status.name),
      appliedAt: Value(appliedAt),
      followUpDate: Value(followUpDate),
      interviewDate: Value(interviewDate),
      interviewStage: Value(interviewStage?.trim().isEmpty == true ? null : interviewStage?.trim()),
      recruiterName: Value(recruiterName?.trim().isEmpty == true ? null : recruiterName?.trim()),
      recruiterContact: Value(recruiterContact?.trim().isEmpty == true ? null : recruiterContact?.trim()),
      resumeId: Value(resumeId),
      resumeUsed: Value(resumeUsed?.trim().isEmpty == true ? null : resumeUsed?.trim()),
      nextAction: Value(nextAction?.trim().isEmpty == true ? null : nextAction?.trim()),
      notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      updatedAt: Value(DateTime.now()),
    );
    await db.updateApplication(companion);
  }

  Future<void> updateApplicationStatus(String id, ApplicationStatus newStatus) async {
    final existing = await db.getApplicationById(id);
    if (existing == null) return;

    final companion = JobApplicationsCompanion(
      id: Value(id),
      jobId: Value(existing.jobId),
      company: Value(existing.company),
      role: Value(existing.role),
      salary: Value(existing.salary),
      location: Value(existing.location),
      url: Value(existing.url),
      status: Value(newStatus.name),
      appliedAt: Value(existing.appliedAt),
      followUpDate: Value(existing.followUpDate),
      interviewDate: Value(existing.interviewDate),
      interviewStage: Value(existing.interviewStage),
      recruiterName: Value(existing.recruiterName),
      recruiterContact: Value(existing.recruiterContact),
      resumeId: Value(existing.resumeId),
      resumeUsed: Value(existing.resumeUsed),
      nextAction: Value(existing.nextAction),
      notes: Value(existing.notes),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(DateTime.now()),
    );
    await db.updateApplication(companion);
  }

  Future<void> deleteApplication(String id) => db.deleteApplication(id);

  // Resume methods
  Future<void> addResume({
    required String name,
    required String version,
    String? targetRole,
    required String filePath,
    required String fileName,
    String? notes,
    bool isPrimary = false,
  }) async {
    final now = DateTime.now();
    final companion = ResumesCompanion(
      id: Value(_uuid.v4()),
      name: Value(name.trim()),
      version: Value(version.trim()),
      targetRole: Value(targetRole?.trim().isEmpty == true ? null : targetRole?.trim()),
      filePath: Value(filePath.trim()),
      fileName: Value(fileName.trim()),
      notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      isPrimary: Value(isPrimary),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await db.insertResume(companion);
    if (isPrimary) {
      await db.setPrimaryResume(companion.id.value);
    }
  }

  Future<void> updateResume({
    required String id,
    required String name,
    required String version,
    String? targetRole,
    required String filePath,
    required String fileName,
    String? notes,
    required bool isPrimary,
  }) async {
    final companion = ResumesCompanion(
      id: Value(id),
      name: Value(name.trim()),
      version: Value(version.trim()),
      targetRole: Value(targetRole?.trim().isEmpty == true ? null : targetRole?.trim()),
      filePath: Value(filePath.trim()),
      fileName: Value(fileName.trim()),
      notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
      isPrimary: Value(isPrimary),
      updatedAt: Value(DateTime.now()),
    );
    await db.updateResume(companion);
    if (isPrimary) {
      await db.setPrimaryResume(id);
    }
  }

  Future<void> setPrimaryResume(String id) => db.setPrimaryResume(id);
  Future<void> deleteResume(String id) => db.deleteResume(id);
}

final careerRepositoryProvider = Provider<CareerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CareerRepository(db);
});

// ==========================================
// RESUME INTELLIGENCE & LIVE DISCOVERY PROVIDERS
// ==========================================

enum ResumeSelectionMode {
  single,
  multi,
  all,
}

final resumeSelectionModeProvider = StateProvider<ResumeSelectionMode>((ref) => ResumeSelectionMode.single);
final singleSelectedResumeIdProvider = StateProvider<String?>((ref) => null);
final multiSelectedResumeIdsProvider = StateProvider<Set<String>>((ref) => <String>{});

final activeResumesProvider = Provider<List<Resume>>((ref) {
  final allResumes = ref.watch(allResumesProvider).valueOrNull ?? [];
  if (allResumes.isEmpty) return [];

  final mode = ref.watch(resumeSelectionModeProvider);
  switch (mode) {
    case ResumeSelectionMode.single:
      final singleId = ref.watch(singleSelectedResumeIdProvider);
      if (singleId != null) {
        final match = allResumes.where((r) => r.id == singleId).toList();
        if (match.isNotEmpty) return match;
      }
      final primary = allResumes.where((r) => r.isPrimary).toList();
      return primary.isNotEmpty ? primary : [allResumes.first];

    case ResumeSelectionMode.multi:
      final selectedIds = ref.watch(multiSelectedResumeIdsProvider);
      if (selectedIds.isNotEmpty) {
        final matches = allResumes.where((r) => selectedIds.contains(r.id)).toList();
        if (matches.isNotEmpty) return matches;
      }
      return [allResumes.first];

    case ResumeSelectionMode.all:
      return allResumes;
  }
});

final parsedResumeProfilesProvider = Provider<Map<String, ResumeProfile>>((ref) {
  final allResumes = ref.watch(allResumesProvider).valueOrNull ?? [];
  final map = <String, ResumeProfile>{};
  for (final resume in allResumes) {
    if (resume.parsedDataJson != null && resume.parsedDataJson!.isNotEmpty) {
      final parsed = ResumeProfile.fromJsonString(resume.parsedDataJson);
      if (parsed != null) {
        map[resume.id] = parsed;
      }
    }
  }
  return map;
});

final activeJobSearchCriteriaProvider = Provider<JobSearchCriteria>((ref) {
  final activeResumes = ref.watch(activeResumesProvider);
  final parsedProfiles = ref.watch(parsedResumeProfilesProvider);
  final profile = ref.watch(careerProfileProvider).valueOrNull;

  return JobSearchCriteriaBuilder.buildCriteria(
    activeResumes: activeResumes,
    parsedProfiles: parsedProfiles,
    profile: profile,
  );
});

final liveJobDiscoveryServiceProvider = Provider<LiveJobDiscoveryService>((ref) {
  final db = ref.watch(databaseProvider);
  return LiveJobDiscoveryService(db: db);
});

class LiveDiscoveryState {
  final bool isLoading;
  final DiscoveryBatchResult? lastResult;
  final String? error;

  const LiveDiscoveryState({
    this.isLoading = false,
    this.lastResult,
    this.error,
  });

  LiveDiscoveryState copyWith({
    bool? isLoading,
    DiscoveryBatchResult? lastResult,
    String? error,
  }) {
    return LiveDiscoveryState(
      isLoading: isLoading ?? this.isLoading,
      lastResult: lastResult ?? this.lastResult,
      error: error,
    );
  }
}

class LiveDiscoveryNotifier extends StateNotifier<LiveDiscoveryState> {
  final Ref _ref;

  LiveDiscoveryNotifier(this._ref) : super(const LiveDiscoveryState());

  Future<DiscoveryBatchResult?> discoverJobs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final criteria = _ref.read(activeJobSearchCriteriaProvider);
      final service = _ref.read(liveJobDiscoveryServiceProvider);
      final result = await service.discoverAndSyncJobs(criteria: criteria);
      state = state.copyWith(isLoading: false, lastResult: result);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final liveDiscoveryProvider = StateNotifierProvider<LiveDiscoveryNotifier, LiveDiscoveryState>((ref) {
  return LiveDiscoveryNotifier(ref);
});
