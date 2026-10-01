import '../jobs/normalized_job.dart';
import '../util/text_normalize.dart';

enum DedupeMatchMethod {
  sourceAndId,
  canonicalUrl,
  fingerprint,
  trigramSimilarity,
  none,
}

class DedupeMatchResult {
  final bool isDuplicate;
  final DedupeMatchMethod method;
  final NormalizedJob? existingJob;

  const DedupeMatchResult({
    required this.isDuplicate,
    this.method = DedupeMatchMethod.none,
    this.existingJob,
  });

  static const unique = DedupeMatchResult(isDuplicate: false);
}

class JobDeduplicator {
  final Map<String, NormalizedJob> _bySourceAndId = {};
  final Map<String, NormalizedJob> _byCanonicalUrl = {};
  final Map<String, NormalizedJob> _byFingerprint = {};
  final List<NormalizedJob> _allJobs = [];

  void add(NormalizedJob job) {
    if (job.atsProvider != null && job.externalId != null) {
      _bySourceAndId['${job.atsProvider}:${job.externalId}'] = job;
    }
    if (job.canonicalUrl.isNotEmpty) {
      _byCanonicalUrl[job.canonicalUrl] = job;
    }
    if (job.fingerprint.isNotEmpty) {
      _byFingerprint[job.fingerprint] = job;
    }
    _allJobs.add(job);
  }

  void addAll(Iterable<NormalizedJob> jobs) {
    for (final j in jobs) {
      add(j);
    }
  }

  DedupeMatchResult check(NormalizedJob candidate) {
    // 1. (source, sourceJobId)
    if (candidate.atsProvider != null && candidate.externalId != null) {
      final key = '${candidate.atsProvider}:${candidate.externalId}';
      final match = _bySourceAndId[key];
      if (match != null) {
        return DedupeMatchResult(
          isDuplicate: true,
          method: DedupeMatchMethod.sourceAndId,
          existingJob: match,
        );
      }
    }

    // 2. canonicalUrl
    if (candidate.canonicalUrl.isNotEmpty) {
      final match = _byCanonicalUrl[candidate.canonicalUrl];
      if (match != null) {
        return DedupeMatchResult(
          isDuplicate: true,
          method: DedupeMatchMethod.canonicalUrl,
          existingJob: match,
        );
      }
    }

    // 3. fingerprint
    if (candidate.fingerprint.isNotEmpty) {
      final match = _byFingerprint[candidate.fingerprint];
      if (match != null) {
        return DedupeMatchResult(
          isDuplicate: true,
          method: DedupeMatchMethod.fingerprint,
          existingJob: match,
        );
      }
    }

    // 4. Same companyNorm and title trigram similarity >= 0.8
    for (final existing in _allJobs) {
      if (existing.companyNorm == candidate.companyNorm) {
        final sim = TextNormalize.trigramSimilarity(existing.titleNorm, candidate.titleNorm);
        if (sim >= 0.8) {
          return DedupeMatchResult(
            isDuplicate: true,
            method: DedupeMatchMethod.trigramSimilarity,
            existingJob: existing,
          );
        }
      }
    }

    return DedupeMatchResult.unique;
  }
}
