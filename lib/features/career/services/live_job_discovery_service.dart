import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/feed_utils.dart';
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
    final index = JobDedupIndex()..addAll(existingJobs);
    return index.check(rawJob);
  }

  static String normalizeUrl(String url) => url
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'^https?://(www\.)?'), '')
      .replaceAll(RegExp(r'[?#].*$'), '')
      .replaceAll(RegExp(r'/+$'), '');

  static String normalizeText(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// URL + company/title index. Checking is O(1) for URLs and O(jobs at that
/// company) for titles, and newly accepted jobs are added so one sync can't
/// insert the same posting twice (RemoteOK and WWR often cross-post).
class JobDedupIndex {
  final _byUrl = <String, Job?>{};
  final _byCompany = <String, List<(String, String?)>>{};

  void addAll(Iterable<Job> jobs) {
    for (final j in jobs) {
      _add(j.url, j.company, j.title, j);
    }
  }

  void addRaw(RawJobItem raw) => _add(raw.url, raw.company, raw.title, null);

  void _add(String? url, String company, String title, Job? job) {
    if (url != null && url.isNotEmpty) _byUrl[JobDeduplicator.normalizeUrl(url)] = job;
    _byCompany
        .putIfAbsent(JobDeduplicator.normalizeText(company), () => [])
        .add((JobDeduplicator.normalizeText(title), job?.id));
  }

  DeduplicationResult check(RawJobItem raw) {
    if (raw.url != null && raw.url!.isNotEmpty) {
      final key = JobDeduplicator.normalizeUrl(raw.url!);
      if (_byUrl.containsKey(key)) {
        final existing = _byUrl[key];
        return DeduplicationResult(
          isDuplicate: true,
          existingJobId: existing?.id,
          reason: 'URL exact match (${existing?.company ?? raw.company})',
        );
      }
    }
    final titles = _byCompany[JobDeduplicator.normalizeText(raw.company)];
    if (titles != null) {
      final t = JobDeduplicator.normalizeText(raw.title);
      for (final (existingTitle, id) in titles) {
        // Exact normalized title only: "Software Engineer" and "Senior
        // Software Engineer, Payments" are different openings.
        if (t == existingTitle) {
          return DeduplicationResult(
            isDuplicate: true,
            existingJobId: id,
            reason: 'Title and company match (${raw.company} - ${raw.title})',
          );
        }
      }
    }
    return const DeduplicationResult.unique();
  }
}

class DiscoveryBatchResult {
  final int totalDiscovered;
  final int newJobsSaved;
  final int duplicatesSkipped;
  final List<SourceStatus> sources;
  final DateTime timestamp;

  const DiscoveryBatchResult({
    required this.totalDiscovered,
    required this.newJobsSaved,
    required this.duplicatesSkipped,
    this.sources = const [],
    required this.timestamp,
  });

  List<SourceStatus> get failedSources => sources.where((s) => !s.ok).toList();
  bool get allSourcesFailed => sources.isNotEmpty && sources.every((s) => !s.ok);

  String get summary {
    final failed = failedSources.length;
    final base = 'Found $totalDiscovered jobs · $newJobsSaved new · $duplicatesSkipped duplicates';
    return failed == 0 ? base : '$base · $failed of ${sources.length} sources failed';
  }
}

class LiveJobDiscoveryService {
  final AppDatabase db;
  final List<JobProvider> _providers;
  static const _uuid = Uuid();

  LiveJobDiscoveryService({
    required this.db,
    List<JobProvider>? customProviders,
  }) : _providers = customProviders ??
            [
              GreenhouseJobProvider(),
              LeverJobProvider(),
              AshbyJobProvider(),
              RemoteOkJobProvider(),
              RssJobProvider(
                providerId: 'WWR',
                providerName: 'WeWorkRemotely',
                feedUrl: 'https://weworkremotely.com/categories/remote-programming-jobs.rss',
              ),
            ];

  /// Fetches every provider in parallel, de-duplicates against the database
  /// and within the batch, and inserts new jobs in a single transaction.
  ///
  /// Never throws for network problems: failures are reported per source in
  /// [DiscoveryBatchResult.sources] and nothing is fabricated to fill gaps.
  Future<DiscoveryBatchResult> discoverAndSyncJobs({
    required JobSearchCriteria criteria,
    bool saveToDatabase = true,
  }) async {
    final query = criteria.roleQueries.isNotEmpty ? criteria.roleQueries.first : null;
    final fetches = await Future.wait(_providers.map((p) async {
      try {
        return await p.fetch(query: query, location: criteria.preferredLocation, remoteOnly: criteria.remoteOnly);
      } catch (e) {
        return JobFetchResult(const [], [SourceStatus(sourceId: p.providerId, label: p.providerName, itemCount: 0, error: e.toString())]);
      }
    }));

    final rawJobs = [for (final f in fetches) ...f.jobs];
    final statuses = [for (final f in fetches) ...f.statuses];

    final index = JobDedupIndex()..addAll(await db.getAllJobs());
    final newJobs = <JobsCompanion>[];
    var duplicates = 0;
    final now = DateTime.now();

    for (final raw in rawJobs) {
      if (raw.url == null || raw.url!.isEmpty) continue; // unclickable -> useless
      if (index.check(raw).isDuplicate) {
        duplicates++;
        continue;
      }
      index.addRaw(raw);
      newJobs.add(toCompanion(raw, _uuid.v4(), now));
    }

    if (saveToDatabase && newJobs.isNotEmpty) {
      await db.batch((batch) => batch.insertAll(db.jobs, newJobs));
    }

    return DiscoveryBatchResult(
      totalDiscovered: rawJobs.length,
      newJobsSaved: newJobs.length,
      duplicatesSkipped: duplicates,
      sources: statuses,
      timestamp: now,
    );
  }

  static const _sourceLabels = {
    'GREENHOUSE': 'Greenhouse',
    'LEVER': 'Lever',
    'REMOTEOK': 'RemoteOK',
    'WWR': 'WeWorkRemotely',
    'ASHBY': 'Ashby',
  };

  /// Maps a feed item onto the Jobs table, clamping to the column limits
  /// (title 200, company 150) so one long feed title can't fail the batch.
  static JobsCompanion toCompanion(RawJobItem raw, String id, DateTime now) {
    return JobsCompanion(
      id: Value(id),
      title: Value(FeedUtils.truncate(raw.title.isEmpty ? 'Untitled role' : raw.title, 200)),
      company: Value(FeedUtils.truncate(raw.company.isEmpty ? 'Unknown company' : raw.company, 150)),
      location: Value(raw.location ?? (raw.isRemote ? 'Remote' : null)),
      salary: Value(raw.salary),
      employmentType: Value(raw.employmentType ?? (raw.isRemote ? 'Remote' : 'Full-time')),
      url: Value(raw.url),
      source: Value(_sourceLabels[raw.atsProvider] ?? raw.atsProvider ?? 'Public feed'),
      description: Value(raw.description == null ? null : FeedUtils.truncate(raw.description!, 12000)),
      skills: Value(raw.skills?.isEmpty == true ? null : raw.skills),
      atsProvider: Value(raw.atsProvider),
      externalId: Value(raw.externalId),
      postedDate: Value(raw.publishedAt),
      discoveredAt: Value(now),
      isSaved: const Value(false),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }
}
