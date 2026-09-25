import '../../../core/database/app_database.dart';
import 'automation_models.dart';

class JobDeduplicator {
  /// Checks if a RawJobItem is a duplicate of any existing Jobs in the database
  static DeduplicationResult isDuplicate(RawJobItem raw, List<Job> existingJobs) {
    final rawCanonicalUrl = _canonicalizeUrl(raw.url);
    final rawNormalizedTitle = _normalizeText(raw.title);
    final rawNormalizedCompany = _normalizeText(raw.company);

    for (final job in existingJobs) {
      // 1. Check exact canonical URL match
      if (rawCanonicalUrl != null && job.url != null) {
        final existingCanonicalUrl = _canonicalizeUrl(job.url);
        if (existingCanonicalUrl != null && existingCanonicalUrl == rawCanonicalUrl) {
          return DeduplicationResult(
            isDuplicate: true,
            reason: 'Canonical URL match (${job.url})',
            matchedJobId: job.id,
          );
        }
      }

      // 2. Check normalized company and title match
      final jobNormalizedTitle = _normalizeText(job.title);
      final jobNormalizedCompany = _normalizeText(job.company);

      if (rawNormalizedCompany == jobNormalizedCompany && rawNormalizedTitle == jobNormalizedTitle) {
        return DeduplicationResult(
          isDuplicate: true,
          reason: 'Identical company and role match (${job.company} - ${job.title})',
          matchedJobId: job.id,
        );
      }

      // 3. Check high similarity (fuzzy match)
      if (rawNormalizedCompany == jobNormalizedCompany) {
        final similarity = _calculateJaccardSimilarity(rawNormalizedTitle, jobNormalizedTitle);
        if (similarity >= 0.85) {
          return DeduplicationResult(
            isDuplicate: true,
            reason: 'High title similarity ($similarity) for same company (${job.company})',
            matchedJobId: job.id,
          );
        }
      }
    }

    return const DeduplicationResult(isDuplicate: false);
  }

  static String? _canonicalizeUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(url.trim());
      // Strip tracking query parameters (utm_*, ref, source) and fragments
      final cleanQueryParameters = Map<String, String>.from(uri.queryParameters)
        ..removeWhere((key, _) => key.startsWith('utm_') || key == 'ref' || key == 'source' || key == 'fbclid');

      final cleanUri = Uri(
        scheme: uri.scheme.toLowerCase(),
        host: uri.host.toLowerCase(),
        path: uri.path.replaceAll(RegExp(r'/+$'), ''), // strip trailing slash
        queryParameters: cleanQueryParameters.isEmpty ? null : cleanQueryParameters,
      );
      return cleanUri.toString();
    } catch (_) {
      return url.trim().toLowerCase();
    }
  }

  static String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static double _calculateJaccardSimilarity(String a, String b) {
    final setA = a.split(' ').where((s) => s.isNotEmpty).toSet();
    final setB = b.split(' ').where((s) => s.isNotEmpty).toSet();
    if (setA.isEmpty && setB.isEmpty) return 1.0;
    if (setA.isEmpty || setB.isEmpty) return 0.0;

    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    return intersection / union;
  }
}
