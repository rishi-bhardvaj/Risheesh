import 'package:http/http.dart' as http;

import '../../../../core/network/feed_utils.dart';

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
  final String? employmentType;

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
    this.employmentType,
  });
}

/// Jobs plus the per-source outcome, so the UI can say "Stripe board timed
/// out" instead of silently showing fewer jobs.
class JobFetchResult {
  final List<RawJobItem> jobs;
  final List<SourceStatus> statuses;

  const JobFetchResult(this.jobs, this.statuses);
}

abstract class JobProvider {
  String get providerId;
  String get providerName;

  Future<JobFetchResult> fetch({String? query, String? location, bool remoteOnly = false});

  Future<List<RawJobItem>> searchJobs({String? query, String? location, bool remoteOnly = false}) async =>
      (await fetch(query: query, location: location, remoteOnly: remoteOnly)).jobs;
}

/// Shared query/location filter. A job matches when any query term longer
/// than two characters appears in its title, description or tags.
bool matchesQuery(String corpus, String? query) {
  if (query == null || query.trim().isEmpty) return true;
  final terms = query.toLowerCase().split(RegExp(r'[\s,/]+')).where((t) => t.length > 2);
  if (terms.isEmpty) return true;
  final lower = corpus.toLowerCase();
  return terms.any(lower.contains);
}

bool matchesLocation(String jobLocation, String? wanted, {required bool isRemote}) {
  if (wanted == null || wanted.trim().isEmpty) return true;
  final w = wanted.toLowerCase().trim();
  if (w == 'remote') return isRemote;
  return isRemote || jobLocation.toLowerCase().contains(w);
}

String? formatSalaryRange(num? min, num? max, {String currency = 'USD', String? interval}) {
  if ((min == null || min <= 0) && (max == null || max <= 0)) return null;
  final symbol = switch (currency.toUpperCase()) {
    'USD' => r'$',
    'EUR' => '€',
    'GBP' => '£',
    'INR' => '₹',
    _ => '$currency ',
  };
  String fmt(num v) => v >= 1000 ? '$symbol${(v / 1000).round()}k' : '$symbol${v.round()}';
  final range = (min != null && min > 0 && max != null && max > 0 && max != min)
      ? '${fmt(min)} – ${fmt(max)}'
      : fmt((min != null && min > 0) ? min : max!);
  final per = switch (interval) {
    'per-hour-wage' || 'hourly' => ' /hr',
    'per-month-salary' => ' /mo',
    _ => '',
  };
  return '$range$per';
}

const _engineeringTags = {
  'dev', 'developer', 'engineer', 'engineering', 'software', 'backend', 'frontend', 'full stack',
  'fullstack', 'mobile', 'android', 'ios', 'flutter', 'react', 'javascript', 'typescript', 'python',
  'golang', 'java', 'ruby', 'rust', 'php', 'devops', 'cloud', 'web dev', 'node', 'data engineer',
  'infrastructure', 'platform', 'security engineering', 'machine learning',
};
final _engineeringTitle = RegExp(
  r'engineer|developer|programmer|architect|devops|\bsre\b|full[\s-]?stack|back[\s-]?end|front[\s-]?end|machine learning|\bml\b|data scien',
  caseSensitive: false,
);

/// True for software/engineering roles, judged by title or by department /
/// tag labels such as "Engineering".
bool isEngineeringRole(String title, Iterable<String> tags) =>
    _engineeringTitle.hasMatch(title) || tags.any((t) => _engineeringTags.contains(t.toLowerCase().trim()));

bool _looksRemote(String location) => RegExp(r'remote|anywhere|worldwide', caseSensitive: false).hasMatch(location);

/// RemoteOK public API. The first array element is a legal notice; the rest
/// are postings across every function, so we keep engineering roles only.
class RemoteOkJobProvider extends JobProvider {
  final http.Client _client;
  final int maxResults;

  RemoteOkJobProvider({http.Client? client, this.maxResults = 50}) : _client = client ?? http.Client();

  @override
  String get providerId => 'REMOTEOK';

  @override
  String get providerName => 'RemoteOK';

  static bool isEngineering(String title, List<String> tags) => isEngineeringRole(title, tags);

  @override
  Future<JobFetchResult> fetch({String? query, String? location, bool remoteOnly = true}) async {
    final sw = Stopwatch()..start();
    try {
      final body = await FeedUtils.getBody(_client, Uri.parse('https://remoteok.com/api'), timeout: const Duration(seconds: 10));
      final list = await FeedUtils.decodeJson(body) as List<dynamic>;
      final results = <RawJobItem>[];

      for (final item in list) {
        if (item is! Map<String, dynamic> || item['position'] == null) continue;
        final title = FeedUtils.decodeEntities(item['position'].toString()).trim();
        final tags = (item['tags'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
        // RemoteOK tags are broad ('dev' appears on design/ops roles), so judge by title.
        if (!isEngineeringRole(title, const [])) continue;

        final description = FeedUtils.htmlToText(item['description'] as String?);
        if (!matchesQuery('$title $description ${tags.join(' ')}', query)) continue;

        final loc = (item['location'] as String?)?.trim();
        results.add(RawJobItem(
          title: title,
          company: FeedUtils.decodeEntities(item['company']?.toString() ?? 'Unknown company'),
          location: (loc == null || loc.isEmpty) ? 'Remote' : 'Remote · $loc',
          salary: formatSalaryRange(item['salary_min'] as num?, item['salary_max'] as num?),
          description: description,
          skills: tags.take(8).join(', '),
          url: (item['url'] ?? item['apply_url'])?.toString(),
          atsProvider: 'REMOTEOK',
          externalId: item['id']?.toString(),
          publishedAt: DateTime.tryParse(item['date']?.toString() ?? ''),
          isRemote: true,
          employmentType: _employmentTypeFromTags(tags, title),
        ));
        if (results.length >= maxResults) break;
      }
      return JobFetchResult(results, [
        SourceStatus(sourceId: providerId, label: providerName, itemCount: results.length, elapsed: sw.elapsed),
      ]);
    } catch (e) {
      return JobFetchResult(const [], [
        SourceStatus(sourceId: providerId, label: providerName, itemCount: 0, error: e.toString(), elapsed: sw.elapsed),
      ]);
    }
  }
}

String _employmentTypeFromTags(List<String> tags, String title) {
  final corpus = '${tags.join(' ')} $title'.toLowerCase();
  if (corpus.contains('contract')) return 'Contract';
  if (corpus.contains('freelance')) return 'Freelance';
  if (corpus.contains('part time') || corpus.contains('part-time')) return 'Part-time';
  return 'Full-time';
}

/// Generic RSS 2.0 job feed. WeWorkRemotely titles are "Company: Role".
class RssJobProvider extends JobProvider {
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
  }) : _client = client ?? http.Client();

  @override
  Future<JobFetchResult> fetch({String? query, String? location, bool remoteOnly = false}) async {
    final sw = Stopwatch()..start();
    try {
      final xml = await FeedUtils.getBody(_client, Uri.parse(feedUrl), headers: FeedUtils.rssHeaders);
      final items = <RawJobItem>[];
      for (final f in FeedUtils.parseRssItems(xml)) {
        final rawTitle = FeedUtils.decodeEntities(f['title'] ?? '').trim();
        if (rawTitle.isEmpty) continue;
        final (company, title) = splitCompanyTitle(rawTitle, fallbackCompany: providerName);
        final description = FeedUtils.htmlToText(f['description']);
        if (!matchesQuery('$title $description $company', query)) continue;

        final region = FeedUtils.decodeEntities(f['region'] ?? '').trim();
        items.add(RawJobItem(
          title: title,
          company: company,
          location: region.isEmpty ? 'Remote' : 'Remote · $region',
          description: description,
          skills: f['skills'] ?? f['category'],
          url: (f['link'] ?? f['guid'])?.trim(),
          atsProvider: providerId,
          externalId: f['guid'],
          publishedAt: FeedUtils.parseFeedDate(f['pubDate']),
          isRemote: true,
          employmentType: _employmentTypeFromTags(const [], '$title ${f['type'] ?? ''}'),
        ));
      }
      return JobFetchResult(items, [
        SourceStatus(sourceId: providerId, label: providerName, itemCount: items.length, elapsed: sw.elapsed),
      ]);
    } catch (e) {
      return JobFetchResult(const [], [
        SourceStatus(sourceId: providerId, label: providerName, itemCount: 0, error: e.toString(), elapsed: sw.elapsed),
      ]);
    }
  }

  /// "Acme Inc: Senior Dev" -> (Acme Inc, Senior Dev); "Senior Dev at Acme" -> (Acme, Senior Dev).
  static (String, String) splitCompanyTitle(String raw, {required String fallbackCompany}) {
    final colon = raw.indexOf(':');
    if (colon > 0 && colon < raw.length - 1) {
      return (raw.substring(0, colon).trim(), raw.substring(colon + 1).trim());
    }
    final at = raw.lastIndexOf(' at ');
    if (at > 0) return (raw.substring(at + 4).trim(), raw.substring(0, at).trim());
    return (fallbackCompany, raw);
  }
}

/// Runs one request per board in parallel; a failing board only affects its
/// own [SourceStatus].
abstract class _MultiBoardProvider extends JobProvider {
  final http.Client client;
  final int maxPerBoard;

  _MultiBoardProvider(http.Client? client, this.maxPerBoard) : client = client ?? http.Client();

  List<String> get boards;
  Uri boardUri(String board);
  List<RawJobItem> parseBoard(String board, dynamic json);

  @override
  Future<JobFetchResult> fetch({String? query, String? location, bool remoteOnly = false}) async {
    final outcomes = await Future.wait(boards.map((board) async {
      final sw = Stopwatch()..start();
      try {
        final body = await FeedUtils.getBody(client, boardUri(board));
        final parsed = parseBoard(board, await FeedUtils.decodeJson(body))
            .where((j) => isEngineeringRole(j.title, (j.skills ?? '').split(',')))
            .where((j) => !remoteOnly || j.isRemote)
            .where((j) => matchesQuery('${j.title} ${j.description ?? ''}', query))
            .where((j) => matchesLocation(j.location ?? '', location, isRemote: j.isRemote))
            .take(maxPerBoard)
            .toList();
        return (parsed, SourceStatus(sourceId: '$providerId:$board', label: '$providerName · $board', itemCount: parsed.length, elapsed: sw.elapsed));
      } catch (e) {
        return (
          const <RawJobItem>[],
          SourceStatus(sourceId: '$providerId:$board', label: '$providerName · $board', itemCount: 0, error: e.toString(), elapsed: sw.elapsed),
        );
      }
    }));
    return JobFetchResult(
      [for (final o in outcomes) ...o.$1],
      [for (final o in outcomes) o.$2],
    );
  }
}

/// Greenhouse Job Board API: https://developers.greenhouse.io/job-board.html
class GreenhouseJobProvider extends _MultiBoardProvider {
  final List<String> boardTokens;

  GreenhouseJobProvider({
    http.Client? client,
    // hashicorp, ramp, retool, deel and rippling no longer publish Greenhouse
    // boards (404 as of Sep 2026); Ramp is served by [AshbyJobProvider].
    this.boardTokens = const [
      'airbnb', 'stripe', 'figma', 'cloudflare', 'databricks', 'gusto',
      'discord', 'gitlab', 'coinbase', 'vercel', 'datadog', 'reddit',
    ],
    int maxPerBoard = 40,
  }) : super(client, maxPerBoard);

  @override
  String get providerId => 'GREENHOUSE';

  @override
  String get providerName => 'Greenhouse';

  @override
  List<String> get boards => boardTokens;

  @override
  Uri boardUri(String board) => Uri.parse('https://boards-api.greenhouse.io/v1/boards/$board/jobs?content=true');

  @override
  List<RawJobItem> parseBoard(String board, dynamic json) {
    final jobs = (json as Map<String, dynamic>)['jobs'] as List<dynamic>? ?? const [];
    return [
      for (final item in jobs.whereType<Map<String, dynamic>>())
        _parse(board, item),
    ];
  }

  RawJobItem _parse(String board, Map<String, dynamic> item) {
    final loc = (item['location'] as Map<String, dynamic>?)?['name']?.toString().trim() ?? '';
    final departments = (item['departments'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((d) => d['name']?.toString() ?? '')
        .where((d) => d.isNotEmpty);
    return RawJobItem(
      title: item['title']?.toString().trim() ?? 'Untitled role',
      company: (item['company_name'] as String?)?.trim().isNotEmpty == true
          ? item['company_name'] as String
          : FeedUtils.prettifyToken(board),
      location: loc.isEmpty ? null : loc,
      description: FeedUtils.htmlToText(item['content'] as String?),
      skills: departments.join(', '),
      url: item['absolute_url'] as String?,
      atsProvider: 'GREENHOUSE',
      externalId: item['id']?.toString(),
      publishedAt: DateTime.tryParse((item['updated_at'] ?? item['first_published'] ?? '').toString()),
      isRemote: _looksRemote(loc),
    );
  }
}

/// Lever Postings API: https://github.com/lever/postings-api
class LeverJobProvider extends _MultiBoardProvider {
  final List<String> organizations;

  LeverJobProvider({
    http.Client? client,
    // deliveroo, atlassian, auth0 and braze left Lever (404 as of Sep 2026).
    this.organizations = const ['palantir', 'spotify', 'shieldai'],
    int maxPerBoard = 40,
  }) : super(client, maxPerBoard);

  @override
  String get providerId => 'LEVER';

  @override
  String get providerName => 'Lever';

  @override
  List<String> get boards => organizations;

  @override
  // `limit` keeps Palantir's board (~6 MB unpaged) inside the timeout.
  Uri boardUri(String board) => Uri.parse('https://api.lever.co/v0/postings/$board?mode=json&limit=80');

  @override
  List<RawJobItem> parseBoard(String board, dynamic json) {
    // Unknown orgs return {"ok": false, "error": "Document not found"}.
    if (json is! List) throw FeedException((json as Map)['error']?.toString() ?? 'Unexpected response');
    return [
      for (final item in json.whereType<Map<String, dynamic>>()) _parse(board, item),
    ];
  }

  RawJobItem _parse(String board, Map<String, dynamic> item) {
    final categories = item['categories'] as Map<String, dynamic>? ?? const {};
    final loc = categories['location']?.toString().trim() ?? '';
    final workplace = item['workplaceType']?.toString() ?? '';
    final salary = item['salaryRange'] as Map<String, dynamic>?;
    final createdAt = item['createdAt'];
    return RawJobItem(
      title: item['text']?.toString().trim() ?? 'Untitled role',
      company: FeedUtils.prettifyToken(board),
      location: loc.isEmpty ? null : loc,
      salary: salary == null
          ? null
          : formatSalaryRange(salary['min'] as num?, salary['max'] as num?,
              currency: salary['currency']?.toString() ?? 'USD', interval: salary['interval']?.toString()),
      description: (item['descriptionPlain'] as String?)?.trim() ?? FeedUtils.htmlToText(item['description'] as String?),
      skills: [categories['team'], categories['department']].whereType<String>().join(', '),
      url: item['hostedUrl'] as String?,
      atsProvider: 'LEVER',
      externalId: item['id']?.toString(),
      publishedAt: createdAt is int ? DateTime.fromMillisecondsSinceEpoch(createdAt) : null,
      isRemote: workplace == 'remote' || _looksRemote(loc),
      employmentType: categories['commitment']?.toString(),
    );
  }
}

/// Ashby Posting API: https://developers.ashbyhq.com/docs/public-job-posting-api
class AshbyJobProvider extends _MultiBoardProvider {
  final List<String> organizations;

  AshbyJobProvider({
    http.Client? client,
    this.organizations = const ['ramp', 'linear', 'supabase', 'notion', 'vanta'],
    int maxPerBoard = 40,
  }) : super(client, maxPerBoard);

  @override
  String get providerId => 'ASHBY';

  @override
  String get providerName => 'Ashby';

  @override
  List<String> get boards => organizations;

  @override
  Uri boardUri(String board) => Uri.parse('https://api.ashbyhq.com/posting-api/job-board/$board?includeCompensation=true');

  @override
  List<RawJobItem> parseBoard(String board, dynamic json) {
    final jobs = (json as Map<String, dynamic>)['jobs'] as List<dynamic>? ?? const [];
    return [
      for (final item in jobs.whereType<Map<String, dynamic>>())
        if (item['isListed'] != false) _parse(board, item),
    ];
  }

  RawJobItem _parse(String board, Map<String, dynamic> item) {
    final loc = item['location']?.toString().trim() ?? '';
    final comp = item['compensation'] as Map<String, dynamic>?;
    final salary = comp?['scrapeableCompensationSalarySummary']?.toString();
    return RawJobItem(
      title: FeedUtils.decodeEntities(item['title']?.toString().trim() ?? 'Untitled role'),
      company: FeedUtils.prettifyToken(board),
      location: loc.isEmpty ? null : loc,
      salary: (salary == null || salary.isEmpty) ? null : salary.replaceAll(' - ', ' – '),
      description: (item['descriptionPlain'] as String?)?.trim() ?? FeedUtils.htmlToText(item['descriptionHtml'] as String?),
      skills: [item['department'], item['team']].whereType<String>().join(', '),
      url: (item['jobUrl'] ?? item['applyUrl'])?.toString(),
      atsProvider: 'ASHBY',
      externalId: item['id']?.toString(),
      publishedAt: DateTime.tryParse(item['publishedAt']?.toString() ?? ''),
      isRemote: item['isRemote'] == true || _looksRemote(loc),
      employmentType: switch (item['employmentType']) {
        'FullTime' => 'Full-time',
        'PartTime' => 'Part-time',
        'Contract' => 'Contract',
        'Intern' => 'Internship',
        _ => null,
      },
    );
  }
}

