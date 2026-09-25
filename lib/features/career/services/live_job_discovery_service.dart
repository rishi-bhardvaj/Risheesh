import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../data/job_providers/public_api_job_provider.dart';
import '../domain/job_search_criteria_builder.dart';

class DeduplicationResult {
  final bool isDuplicate;
  final String? existingJobId;
  final String? reason;

  const DeduplicationResult({
    required this.isDuplicate,
    this.existingJobId,
    this.reason,
  });

  const DeduplicationResult.unique()
      : isDuplicate = false,
        existingJobId = null,
        reason = null;
}

class JobDeduplicator {
  static DeduplicationResult isDuplicate(RawJobItem rawJob, List<Job> existingJobs) {
    // 1. Exact URL match
    if (rawJob.url != null && rawJob.url!.isNotEmpty) {
      final normalizedRawUrl = _normalizeUrl(rawJob.url!);
      for (final existing in existingJobs) {
        if (existing.url != null && _normalizeUrl(existing.url!) == normalizedRawUrl) {
          return DeduplicationResult(
            isDuplicate: true,
            existingJobId: existing.id,
            reason: 'URL exact match (${existing.company})',
          );
        }
      }
    }

    // 2. Company + Title fuzzy normalized match
    final cleanRawCompany = _normalizeText(rawJob.company);
    final cleanRawTitle = _normalizeText(rawJob.title);

    for (final existing in existingJobs) {
      final cleanExistingCompany = _normalizeText(existing.company);
      final cleanExistingTitle = _normalizeText(existing.title);

      if (cleanRawCompany == cleanExistingCompany &&
          (cleanRawTitle == cleanExistingTitle ||
           cleanRawTitle.contains(cleanExistingTitle) ||
           cleanExistingTitle.contains(cleanRawTitle))) {
        return DeduplicationResult(
          isDuplicate: true,
          existingJobId: existing.id,
          reason: 'Title and company match (${existing.company} - ${existing.title})',
        );
      }
    }

    return const DeduplicationResult.unique();
  }

  static String _normalizeUrl(String url) {
    return url.toLowerCase().replaceAll(RegExp(r'\?.*$'), '').replaceAll(RegExp(r'\/+$'), '');
  }

  static String _normalizeText(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class DiscoveryBatchResult {
  final int totalDiscovered;
  final int newJobsSaved;
  final int duplicatesSkipped;
  final List<Job> currentJobs;
  final String? errorMessage;
  final DateTime timestamp;

  const DiscoveryBatchResult({
    required this.totalDiscovered,
    required this.newJobsSaved,
    required this.duplicatesSkipped,
    required this.currentJobs,
    this.errorMessage,
    required this.timestamp,
  });
}

class LiveJobDiscoveryService {
  final AppDatabase db;
  final List<JobProvider> _providers;
  final _uuid = const Uuid();

  LiveJobDiscoveryService({
    required this.db,
    List<JobProvider>? customProviders,
  })  : _providers = customProviders ??
            [
              RemoteOkJobProvider(),
              RssJobProvider(
                providerId: 'WWR_DEVELOPMENT',
                providerName: 'WeWorkRemotely Dev',
                feedUrl: 'https://weworkremotely.com/categories/remote-programming-jobs.rss',
              ),
              RssJobProvider(
                providerId: 'REMOTIVE_ALL',
                providerName: 'Remotive Feed',
                feedUrl: 'https://remotive.com/remote-jobs/feed',
              ),
            ];

  Future<DiscoveryBatchResult> discoverAndSyncJobs({
    required JobSearchCriteria criteria,
    bool saveToDatabase = true,
  }) async {
    final rawJobs = <RawJobItem>[];
    String? lastError;

    for (final provider in _providers) {
      try {
        final query = criteria.roleQueries.isNotEmpty ? criteria.roleQueries.first : null;
        final jobs = await provider.searchJobs(
          query: query,
          location: criteria.preferredLocation,
          remoteOnly: criteria.remoteOnly,
        );
        rawJobs.addAll(jobs);
      } catch (e) {
        lastError = 'Provider ${provider.providerName} error: $e';
      }
    }

    final existingJobs = await db.getAllJobs();

    if (rawJobs.isEmpty && lastError != null) {
      return DiscoveryBatchResult(
        totalDiscovered: 0,
        newJobsSaved: 0,
        duplicatesSkipped: 0,
        currentJobs: existingJobs,
        errorMessage: lastError,
        timestamp: DateTime.now(),
      );
    }

    final newJobs = <JobsCompanion>[];
    int duplicates = 0;

    for (final raw in rawJobs) {
      final dedupResult = JobDeduplicator.isDuplicate(raw, existingJobs);
      if (dedupResult.isDuplicate) {
        duplicates++;
        continue;
      }

      final companion = JobsCompanion(
        id: Value(_uuid.v4()),
        title: Value(raw.title),
        company: Value(raw.company),
        location: Value(raw.location ?? (raw.isRemote ? 'Remote' : 'Various')),
        salary: Value(raw.salary),
        employmentType: Value(raw.isRemote ? 'Remote' : 'Full-time'),
        url: Value(raw.url),
        source: Value(raw.isRemote ? 'RemoteOK / RSS' : 'Public Feed'),
        description: Value(raw.description),
        skills: Value(raw.skills),
        atsProvider: Value(raw.isRemote ? 'REMOTEOK' : 'RSS_FEED'),
        postedDate: Value(raw.publishedAt ?? DateTime.now()),
        discoveredAt: Value(DateTime.now()),
        isSaved: const Value(false),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );

      newJobs.add(companion);
    }

    if (saveToDatabase && newJobs.isNotEmpty) {
      await db.batch((batch) {
        batch.insertAll(db.jobs, newJobs);
      });
    }

    final allUpdatedJobs = await db.getAllJobs();

    return DiscoveryBatchResult(
      totalDiscovered: rawJobs.length,
      newJobsSaved: newJobs.length,
      duplicatesSkipped: duplicates,
      currentJobs: allUpdatedJobs,
      timestamp: DateTime.now(),
    );
  }
}
