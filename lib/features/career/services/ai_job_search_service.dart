import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/ai/ai_clients.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/feed_utils.dart';
import '../data/job_providers/public_api_job_provider.dart';
import 'live_job_discovery_service.dart';

class AiJobSearchResult {
  final int found;
  final int saved;
  final int deadLinks;
  final int duplicates;

  const AiJobSearchResult(this.found, this.saved, this.deadLinks, this.duplicates);

  String get summary =>
      'AI search: $saved new of $found jobs${deadLinks > 0 ? ' · $deadLinks dead links dropped' : ''}${duplicates > 0 ? ' · $duplicates already saved' : ''}';
}

/// Live job search with Claude + web search. Covers what public ATS APIs
/// can't: Naukri, LinkedIn, Instahyre, Wellfound, Cutshort and company pages.
class AiJobSearchService {
  final AppDatabase db;
  final ClaudeClient claude;
  final http.Client _http;
  static const _uuid = Uuid();

  AiJobSearchService({required this.db, required this.claude, http.Client? client}) : _http = client ?? http.Client();

  static Map<String, dynamic> _nullable(String type) => {
        'anyOf': [
          {'type': type},
          {'type': 'null'},
        ],
      };

  static final schema = <String, dynamic>{
    'type': 'object',
    'additionalProperties': false,
    'required': ['jobs'],
    'properties': {
      'jobs': {
        'type': 'array',
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['title', 'company', 'location', 'url', 'posted', 'salary', 'employment_type', 'summary', 'skills'],
          'properties': {
            'title': {'type': 'string'},
            'company': {'type': 'string'},
            'location': {'type': 'string'},
            'url': {'type': 'string', 'description': 'Direct link to the posting'},
            'posted': _nullable('string'),
            'salary': _nullable('string'),
            'employment_type': _nullable('string'),
            'summary': {'type': 'string', 'description': '2-3 sentences: team, stack, what the role does'},
            'skills': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
        },
      },
    },
  };

  static const _system = '''
You find currently open job postings for a software professional. Only report postings you actually saw in search results, with the direct posting URL (company careers page, LinkedIn, Naukri, Instahyre, Wellfound, Cutshort, Greenhouse/Lever/Ashby boards). Never invent companies, links or salaries. Prefer postings from the last 30 days and skip ones that say they are closed.''';

  Future<AiJobSearchResult> search({required String query, String? location, List<String> skills = const [], int count = 12}) async {
    final prompt = [
      'Find $count open roles matching: "$query".',
      if (location != null && location.trim().isNotEmpty) 'Location: $location (remote roles open to this location also count).',
      if (skills.isNotEmpty) 'Candidate skills: ${skills.take(15).join(', ')}.',
      'Call submit_jobs with what you find.',
    ].join('\n');

    final research = await claude.research(
      system: _system,
      prompt: prompt,
      resultTool: 'submit_jobs',
      resultDescription: 'Submit the job postings you found.',
      resultSchema: schema,
      maxSearches: 8,
    );
    final items = (research.data['jobs'] as List? ?? const []).whereType<Map>().toList();

    final checks = await Future.wait(items.map((j) => _alive(j['url']?.toString())));
    final index = JobDedupIndex()..addAll(await db.getAllJobs());
    final inserts = <JobsCompanion>[];
    var dead = 0, dupes = 0;
    final now = DateTime.now();

    for (var i = 0; i < items.length; i++) {
      final j = items[i];
      if (!checks[i]) {
        dead++;
        continue;
      }
      final raw = RawJobItem(
        title: FeedUtils.decodeEntities(j['title']?.toString() ?? '').trim(),
        company: FeedUtils.decodeEntities(j['company']?.toString() ?? '').trim(),
        location: j['location']?.toString(),
        salary: j['salary']?.toString(),
        description: j['summary']?.toString(),
        skills: (j['skills'] as List? ?? const []).join(', '),
        url: j['url']?.toString(),
        atsProvider: 'AI_SEARCH',
        publishedAt: DateTime.tryParse(j['posted']?.toString() ?? ''),
        isRemote: (j['location']?.toString() ?? '').toLowerCase().contains('remote'),
        employmentType: j['employment_type']?.toString(),
      );
      if (raw.title.isEmpty || raw.company.isEmpty) continue;
      if (index.check(raw).isDuplicate) {
        dupes++;
        continue;
      }
      index.addRaw(raw);
      inserts.add(LiveJobDiscoveryService.toCompanion(raw, _uuid.v4(), now).copyWith(source: const Value('AI search')));
    }
    if (inserts.isNotEmpty) await db.batch((b) => b.insertAll(db.jobs, inserts));
    return AiJobSearchResult(items.length, inserts.length, dead, dupes);
  }

  /// False only for definite dead links (404/410). Job boards often block
  /// bots (403/999) or time out, which says nothing about the posting.
  Future<bool> _alive(String? url) async {
    if (url == null || !url.startsWith('http')) return false;
    try {
      final r = await _http.get(Uri.parse(url), headers: {'User-Agent': FeedUtils.userAgent}).timeout(const Duration(seconds: 8));
      return r.statusCode != 404 && r.statusCode != 410;
    } catch (_) {
      return true;
    }
  }
}
