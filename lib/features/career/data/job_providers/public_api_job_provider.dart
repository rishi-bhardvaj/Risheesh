import 'dart:convert';
import 'package:http/http.dart' as http;

class RawJobItem {
  final String title;
  final String company;
  final String? location;
  final String? salary;
  final String? description;
  final String? skills;
  final String? url;
  final String? atsProvider;
  final String? externalId;
  final DateTime? publishedAt;
  final bool isRemote;

  const RawJobItem({
    required this.title,
    required this.company,
    this.location,
    this.salary,
    this.description,
    this.skills,
    this.url,
    this.atsProvider,
    this.externalId,
    this.publishedAt,
    this.isRemote = true,
  });
}

abstract class JobProvider {
  String get providerId;
  String get providerName;
  Future<List<RawJobItem>> searchJobs({
    String? query,
    String? location,
    bool remoteOnly = false,
  });
}

class RemoteOkJobProvider implements JobProvider {
  final http.Client _client;

  RemoteOkJobProvider({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get providerId => 'REMOTEOK';

  @override
  String get providerName => 'RemoteOK Public API';

  @override
  Future<List<RawJobItem>> searchJobs({
    String? query,
    String? location,
    bool remoteOnly = true,
  }) async {
    try {
      final uri = Uri.parse('https://remoteok.com/api');
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final results = <RawJobItem>[];

        for (final item in list) {
          if (item is! Map<String, dynamic> || !item.containsKey('id') || !item.containsKey('position')) {
            continue;
          }

          final title = item['position'] as String? ?? 'Engineer';
          final company = item['company'] as String? ?? 'Remote Tech';
          final loc = item['location'] as String? ?? 'Remote Worldwide';
          final tags = (item['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          final description = _stripHtml(item['description'] as String? ?? '');

          if (query != null && query.trim().isNotEmpty) {
            final qTerms = query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.length > 2);
            if (qTerms.isNotEmpty) {
              final searchCorpus = '$title $description ${tags.join(' ')}'.toLowerCase();
              final matches = qTerms.any((term) => searchCorpus.contains(term));
              if (!matches) continue;
            }
          }

          final dateStr = item['date'] as String?;
          DateTime? date;
          if (dateStr != null) {
            date = DateTime.tryParse(dateStr);
          }

          results.add(
            RawJobItem(
              title: title,
              company: company,
              location: loc,
              salary: item['salary_min'] != null && item['salary_max'] != null
                  ? '\$${item['salary_min']} - \$${item['salary_max']}'
                  : null,
              description: description,
              skills: tags.join(', '),
              url: item['url'] as String? ?? (item['apply_url'] as String?),
              atsProvider: 'REMOTEOK',
              externalId: item['id']?.toString(),
              publishedAt: date ?? DateTime.now(),
              isRemote: true,
            ),
          );
        }

        return results;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class RssJobProvider implements JobProvider {
  @override
  final String providerId;
  @override
  final String providerName;
  final String feedUrl;
  final http.Client _client;

  RssJobProvider({
    required this.providerId,
    required this.providerName,
    required this.feedUrl,
    http.Client? client,
  })  : _client = client ?? http.Client();

  @override
  Future<List<RawJobItem>> searchJobs({
    String? query,
    String? location,
    bool remoteOnly = false,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(feedUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final xml = response.body;
        final items = <RawJobItem>[];
        final itemRegex = RegExp(r'<item>(.*?)<\/item>', dotAll: true);
        final matches = itemRegex.allMatches(xml);

        for (final m in matches) {
          final block = m.group(1) ?? '';
          final title = _extractTag(block, 'title') ?? 'Job Opportunity';
          final link = _extractTag(block, 'link');
          final description = _stripHtml(_extractTag(block, 'description') ?? '');
          final pubDateStr = _extractTag(block, 'pubDate');

          String company = providerName;
          String cleanTitle = title;
          if (title.contains(':')) {
            final parts = title.split(':');
            company = parts.first.trim();
            cleanTitle = parts.sublist(1).join(':').trim();
          } else if (title.contains(' at ')) {
            final parts = title.split(' at ');
            cleanTitle = parts.first.trim();
            company = parts.sublist(1).join(' at ').trim();
          }

          if (query != null && query.isNotEmpty) {
            final qTerms = query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.length > 2);
            if (qTerms.isNotEmpty) {
              final searchCorpus = '$cleanTitle $description $company'.toLowerCase();
              final matches = qTerms.any((term) => searchCorpus.contains(term));
              if (!matches) continue;
            }
          }

          items.add(
            RawJobItem(
              title: cleanTitle,
              company: company,
              location: 'Remote',
              description: description,
              url: link,
              atsProvider: 'RSS_FEED',
              publishedAt: pubDateStr != null ? DateTime.tryParse(pubDateStr) ?? DateTime.now() : DateTime.now(),
              isRemote: true,
            ),
          );
        }

        return items;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  String? _extractTag(String block, String tag) {
    final match = RegExp('<$tag.*?>(?:<!\\[CDATA\\[)?(.*?)(?:\\]\\]>)?<\\/$tag>', dotAll: true).firstMatch(block);
    return match?.group(1)?.trim();
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class GreenhouseJobProvider implements JobProvider {
  final http.Client _client;
  final List<String> boardTokens;

  GreenhouseJobProvider({
    http.Client? client,
    this.boardTokens = const [
      'airbnb', 'stripe', 'figma', 'cloudflare', 'databricks',
      'gusto', 'hashicorp', 'discord', 'ramp', 'retool', 'deel', 'rippling'
    ],
  }) : _client = client ?? http.Client();

  @override
  String get providerId => 'GREENHOUSE';

  @override
  String get providerName => 'Greenhouse Public API';

  @override
  Future<List<RawJobItem>> searchJobs({
    String? query,
    String? location,
    bool remoteOnly = false,
  }) async {
    final futures = boardTokens.map((token) async {
      try {
        final uri = Uri.parse('https://boards-api.greenhouse.io/v1/boards/$token/jobs?content=true');
        final response = await _client.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final List<dynamic> jobs = data['jobs'] ?? [];
          final boardResults = <RawJobItem>[];

          for (final item in jobs.take(30)) {
            if (item is! Map<String, dynamic>) continue;

            final title = item['title'] as String? ?? 'Engineer';
            final locName = item['location']?['name'] as String? ?? 'Remote';
            final description = _stripHtml(item['content'] as String? ?? '');

            if (query != null && query.trim().isNotEmpty) {
              final qTerms = query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.length > 2);
              if (qTerms.isNotEmpty) {
                final searchCorpus = '$title $description'.toLowerCase();
                final matches = qTerms.any((term) => searchCorpus.contains(term));
                if (!matches) continue;
              }
            }
            if (location != null && location.isNotEmpty) {
              if (!locName.toLowerCase().contains(location.toLowerCase())) {
                continue;
              }
            }

            final dateStr = item['updated_at'] as String?;
            DateTime? date;
            if (dateStr != null) {
              date = DateTime.tryParse(dateStr);
            }

            boardResults.add(
              RawJobItem(
                title: title,
                company: token.toUpperCase(),
                location: locName,
                description: description,
                url: item['absolute_url'] as String?,
                atsProvider: 'GREENHOUSE',
                publishedAt: date ?? DateTime.now(),
                isRemote: locName.toLowerCase().contains('remote'),
              ),
            );
          }
          return boardResults;
        }
      } catch (_) {}
      return <RawJobItem>[];
    });

    final allResults = await Future.wait(futures);
    return allResults.expand((element) => element).toList();
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class LeverJobProvider implements JobProvider {
  final http.Client _client;
  final List<String> organizations;

  LeverJobProvider({
    http.Client? client,
    this.organizations = const [
      'palantir', 'deliveroo', 'atlassian', 'auth0', 'braze'
    ],
  }) : _client = client ?? http.Client();

  @override
  String get providerId => 'LEVER';

  @override
  String get providerName => 'Lever Public API';

  @override
  Future<List<RawJobItem>> searchJobs({
    String? query,
    String? location,
    bool remoteOnly = false,
  }) async {
    final futures = organizations.map((org) async {
      try {
        final uri = Uri.parse('https://api.lever.co/v0/postings/$org?mode=json');
        final response = await _client.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final List<dynamic> jobs = jsonDecode(response.body);
          final orgResults = <RawJobItem>[];

          for (final item in jobs.take(30)) {
            if (item is! Map<String, dynamic>) continue;

            final title = item['text'] as String? ?? 'Engineer';
            final locName = item['categories']?['location'] as String? ?? 'Remote';
            final description = _stripHtml(item['descriptionPlain'] as String? ?? '');

            if (query != null && query.trim().isNotEmpty) {
              final qTerms = query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.length > 2);
              if (qTerms.isNotEmpty) {
                final searchCorpus = '$title $description'.toLowerCase();
                final matches = qTerms.any((term) => searchCorpus.contains(term));
                if (!matches) continue;
              }
            }
            if (location != null && location.isNotEmpty) {
              if (!locName.toLowerCase().contains(location.toLowerCase())) {
                continue;
              }
            }

            final timestamp = item['createdAt'];
            DateTime? date;
            if (timestamp is int) {
              date = DateTime.fromMillisecondsSinceEpoch(timestamp);
            }

            orgResults.add(
              RawJobItem(
                title: title,
                company: org.toUpperCase(),
                location: locName,
                description: description,
                url: item['hostedUrl'] as String?,
                atsProvider: 'LEVER',
                publishedAt: date ?? DateTime.now(),
                isRemote: locName.toLowerCase().contains('remote'),
              ),
            );
          }
          return orgResults;
        }
      } catch (_) {}
      return <RawJobItem>[];
    });

    final allResults = await Future.wait(futures);
    return allResults.expand((element) => element).toList();
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
