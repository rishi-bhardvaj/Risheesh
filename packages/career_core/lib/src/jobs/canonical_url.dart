class CanonicalUrl {
  CanonicalUrl._();

  static const _stripParams = {
    'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content',
    'ref', 'ref_id', 'trk', 'tracking', 'source', 'gh_src', 'lever-source',
    'fbclid', 'gclid', 'msclkid', 'mc_cid', 'mc_eid',
  };

  static String normalize(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    try {
      final uri = Uri.parse(rawUrl.trim());
      final host = uri.host.toLowerCase();
      var path = uri.path;

      // 1. LinkedIn currentJobId rewrite
      if (host.contains('linkedin.com')) {
        final jobId = uri.queryParameters['currentJobId'];
        if (jobId != null && jobId.isNotEmpty) {
          return 'https://www.linkedin.com/jobs/view/$jobId';
        }
        final match = RegExp(r'/jobs/view/(\d+)').firstMatch(path);
        if (match != null) {
          return 'https://www.linkedin.com/jobs/view/${match.group(1)}';
        }
      }

      // 2. Greenhouse canonical form: boards.greenhouse.io/{board}/jobs/{id}
      if (host.contains('greenhouse.io')) {
        final match = RegExp(r'/(?:embed/job_app|v1/boards)/?([^/]+)/jobs/(\d+)|/([^/]+)/jobs/(\d+)').firstMatch(path);
        if (match != null) {
          final board = match.group(1) ?? match.group(3);
          final id = match.group(2) ?? match.group(4);
          if (board != null && id != null) {
            return 'https://boards.greenhouse.io/$board/jobs/$id';
          }
        }
      }

      // 3. Lever canonical form: jobs.lever.co/{org}/{id}
      if (host.contains('lever.co')) {
        final match = RegExp(r'/([^/]+)/([a-f0-9\-]{36}|[a-zA-Z0-9]+)').firstMatch(path);
        if (match != null) {
          final org = match.group(1);
          final id = match.group(2);
          if (org != null && id != null) {
            return 'https://jobs.lever.co/$org/$id';
          }
        }
      }

      // 4. Strip tracking parameters and fragments
      final cleanParams = Map<String, String>.from(uri.queryParameters)
        ..removeWhere((key, _) => _stripParams.contains(key.toLowerCase()) || key.toLowerCase().startsWith('utm_'));

      final cleanUri = Uri(
        scheme: uri.scheme.isNotEmpty ? uri.scheme.toLowerCase() : 'https',
        userInfo: uri.userInfo,
        host: host,
        port: (uri.port == 80 || uri.port == 443) ? null : uri.port,
        path: path.endsWith('/') && path.length > 1 ? path.substring(0, path.length - 1) : path,
        queryParameters: cleanParams.isEmpty ? null : cleanParams,
      );

      return cleanUri.toString();
    } catch (_) {
      return rawUrl.trim();
    }
  }
}
