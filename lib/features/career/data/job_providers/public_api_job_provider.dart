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
      final tag = query?.replaceAll(RegExp(r'\s+'), '-').toLowerCase() ?? 'dev';
      final uri = Uri.parse('https://remoteok.com/api?tag=$tag');
      final response = await _client.get(
        uri,
        headers: {'User-Agent': 'CareerOS-App/1.0 (Personal Career Intelligence)'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final results = <RawJobItem>[];

        for (final item in list) {
          if (item is! Map<String, dynamic> || !item.containsKey('id') || !item.containsKey('position')) {
            continue;
          }

          final tags = (item['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          final dateStr = item['date'] as String?;
          DateTime? date;
          if (dateStr != null) {
            date = DateTime.tryParse(dateStr);
          }

          results.add(
            RawJobItem(
              title: item['position'] as String? ?? 'Engineer',
              company: item['company'] as String? ?? 'Remote Company',
              location: item['location'] as String? ?? 'Remote',
              salary: item['salary_min'] != null && item['salary_max'] != null
                  ? '\$${item['salary_min']} - \$${item['salary_max']}'
                  : null,
              description: _stripHtml(item['description'] as String? ?? ''),
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
        headers: {'User-Agent': 'CareerOS-App/1.0 (Personal Career Intelligence)'},
      ).timeout(const Duration(seconds: 12));

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

          // Parse Company: Title pattern (standard in job RSS)
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
            final q = query.toLowerCase();
            if (!cleanTitle.toLowerCase().contains(q) &&
                !description.toLowerCase().contains(q) &&
                !company.toLowerCase().contains(q)) {
              continue;
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
