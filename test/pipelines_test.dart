import 'dart:convert';

import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/core/network/feed_utils.dart';
import 'package:career_os/features/career/data/job_providers/public_api_job_provider.dart';
import 'package:career_os/features/career/domain/job_search_criteria_builder.dart';
import 'package:career_os/features/career/domain/salary_parser.dart';
import 'package:career_os/features/career/services/live_job_discovery_service.dart';
import 'package:career_os/features/track/providers/track_providers.dart';
import 'package:career_os/features/track/services/apas_dsa_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('FeedUtils', () {
    test('unescapes Greenhouse-style HTML before stripping tags', () {
      const escaped = '&lt;div&gt;&lt;p&gt;Build &amp;amp; ship&lt;/p&gt;&lt;ul&gt;&lt;li&gt;Dart&lt;/li&gt;&lt;li&gt;Go&lt;/li&gt;&lt;/ul&gt;&lt;/div&gt;';
      expect(FeedUtils.htmlToText(escaped), 'Build & ship\n• Dart\n• Go');
    });

    test('repairs UTF-8 text that was decoded as Windows-1252 upstream', () {
      expect(FeedUtils.repairMojibake('grabaciÃ³n de tareas'), 'grabación de tareas');
      expect(FeedUtils.repairMojibake(r'$211.4K â€“ $290.6K'), r'$211.4K – $290.6K');
      expect(FeedUtils.repairMojibake('Café – déjà vu'), 'Café – déjà vu');
    });

    test('parses RFC-822 pubDate with offset', () {
      final d = FeedUtils.parseFeedDate('Mon, 28 Sep 2026 14:03:11 +0200')!;
      expect(d.toUtc(), DateTime.utc(2026, 9, 28, 12, 3, 11));
      expect(FeedUtils.parseFeedDate('2026-09-20T10:00:00Z'), DateTime.utc(2026, 9, 20, 10));
      expect(FeedUtils.parseFeedDate('not a date'), isNull);
    });
  });

  group('Job providers', () {
    test('Greenhouse uses company_name, decodes content, reports failing boards', () async {
      final client = MockClient((req) async {
        if (req.url.path.contains('/stripe/')) {
          return http.Response(
            jsonEncode({
              'jobs': [
                {
                  'id': 1,
                  'title': 'Backend Engineer',
                  'company_name': 'Stripe',
                  'absolute_url': 'https://stripe.com/jobs/1',
                  'location': {'name': 'Remote - US'},
                  'updated_at': '2026-09-20T10:00:00Z',
                  'content': '&lt;p&gt;Payments at scale&lt;/p&gt;',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });
      final result = await GreenhouseJobProvider(client: client, boardTokens: ['stripe', 'nope']).fetch();
      expect(result.jobs.single.company, 'Stripe');
      expect(result.jobs.single.description, 'Payments at scale');
      expect(result.jobs.single.isRemote, isTrue);
      final failed = result.statuses.where((s) => !s.ok).toList();
      expect(failed.single.label, contains('nope'));
      expect(failed.single.error, contains('404'));
    });

    test('RemoteOK keeps engineering roles only, caps at maxResults, hides \$0 salaries', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode([
              {'legal': 'notice'},
              {'id': 1, 'position': 'Director of Payment Integrity', 'company': 'Ins', 'tags': ['exec', 'legal'], 'url': 'https://r/1', 'salary_min': 0, 'salary_max': 0},
              for (var i = 2; i < 70; i++)
                {'id': i, 'position': 'Senior Flutter Engineer $i', 'company': 'Co$i', 'tags': ['flutter', 'dev'], 'url': 'https://r/$i', 'salary_min': 0, 'salary_max': 0},
            ]),
            200,
          ));
      final result = await RemoteOkJobProvider(client: client).fetch();
      expect(result.jobs, hasLength(50));
      expect(result.jobs.any((j) => j.title.contains('Director')), isFalse);
      expect(result.jobs.every((j) => j.salary == null), isTrue);
    });

    test('Ashby parses listed engineering roles with compensation; non-engineering filtered', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({
              'jobs': [
                {
                  'id': 'a1',
                  'title': 'Security Engineer, Cloud',
                  'department': 'Engineering',
                  'location': 'New York, NY',
                  'isRemote': true,
                  'isListed': true,
                  'employmentType': 'FullTime',
                  'jobUrl': 'https://jobs.ashbyhq.com/ramp/a1',
                  'publishedAt': '2026-04-07T17:12:35.753+00:00',
                  'descriptionPlain': 'Secure cloud infra.',
                  'compensation': {'scrapeableCompensationSalarySummary': r'$211.4K - $290.6K'},
                },
                {'id': 'a2', 'title': 'Accountant', 'department': 'Finance', 'isListed': true, 'jobUrl': 'https://jobs.ashbyhq.com/ramp/a2'},
                {'id': 'a3', 'title': 'Backend Engineer', 'isListed': false, 'jobUrl': 'https://jobs.ashbyhq.com/ramp/a3'},
              ],
            }),
            200,
          ));
      final result = await AshbyJobProvider(client: client, organizations: ['ramp']).fetch();
      final job = result.jobs.single;
      expect(job.title, 'Security Engineer, Cloud');
      expect(job.company, 'Ramp');
      expect(job.salary, r'$211.4K – $290.6K');
      expect(job.isRemote, isTrue);
      expect(job.employmentType, 'Full-time');
      expect(SalaryParser.parse(job.salary)!.max, closeTo(290600, 1));
    });

    test('formatSalaryRange', () {
      expect(formatSalaryRange(120000, 160000), r'$120k – $160k');
      expect(formatSalaryRange(0, 0), isNull);
      expect(formatSalaryRange(90, 150, interval: 'hourly'), r'$90 – $150 /hr');
    });
  });

  group('LiveJobDiscoveryService', () {
    test('dedupes across providers within one sync and never fabricates jobs', () async {
      final duplicate = [
        const RawJobItem(title: 'Flutter Engineer', company: 'Acme', url: 'https://acme.dev/jobs/1?utm=x', atsProvider: 'REMOTEOK'),
        const RawJobItem(title: 'Flutter Engineer', company: 'Acme', url: 'https://www.acme.dev/jobs/1', atsProvider: 'WWR'),
        RawJobItem(title: 'T' * 260, company: 'LongCo', url: 'https://long.co/1', atsProvider: 'WWR'),
      ];
      final service = LiveJobDiscoveryService(db: db, customProviders: [_FakeProvider(duplicate), _FailingProvider()]);
      final result = await service.discoverAndSyncJobs(criteria: const JobSearchCriteria(roleQueries: [], topSkills: []));
      expect(result.newJobsSaved, 2);
      expect(result.duplicatesSkipped, 1);
      expect(result.failedSources, hasLength(1));
      final jobs = await db.getAllJobs();
      expect(jobs.firstWhere((j) => j.company == 'LongCo').title.length, 200);

      // Everything offline: nothing is invented.
      final offlineDb = AppDatabase(NativeDatabase.memory());
      addTearDown(offlineDb.close);
      final offline = LiveJobDiscoveryService(db: offlineDb, customProviders: [_FailingProvider()]);
      final r2 = await offline.discoverAndSyncJobs(criteria: const JobSearchCriteria(roleQueries: [], topSkills: []));
      expect(r2.allSourcesFailed, isTrue);
      expect(r2.newJobsSaved, 0);
    });
  });

  group('ApasDsaService', () {
    Map<String, dynamic> page(int skip) => {
          'data': {
            'problemsetQuestionList': {
              'total': 4000,
              'questions': [
                for (var i = 1; i <= 100; i++)
                  {
                    'acRate': 50.5,
                    'difficulty': i.isEven ? 'Easy' : 'Hard',
                    'frontendQuestionId': '${skip + i}',
                    'paidOnly': i == 3,
                    'title': 'Problem ${skip + i}',
                    'titleSlug': 'problem-${skip + i}',
                    'topicTags': [
                      {'name': 'Array', 'slug': 'array'},
                      {'name': i.isEven ? 'Depth-First Search' : 'Dynamic Programming', 'slug': i.isEven ? 'depth-first-search' : 'dynamic-programming'},
                    ],
                  },
              ],
            },
          },
        };

    test('fetches 5 pages of 100 in parallel and tolerates a failed page', () async {
      final skips = <int>[];
      final client = MockClient((req) async {
        final skip = (jsonDecode(req.body)['variables']['skip'] as num).toInt();
        skips.add(skip);
        if (skip == 300) return http.Response('busy', 502);
        return http.Response(jsonEncode(page(skip)), 200);
      });
      final result = await ApasDsaService(db: db, client: client).sync(limit: 500);
      expect(skips..sort(), [0, 100, 200, 300, 400]);
      expect(result.fetch.fromNetwork, isTrue);
      expect(result.fetch.pagesFailed, 1);
      expect(result.added, 400);

      final problems = await db.getAllDSAProblems();
      final p2 = problems.firstWhere((p) => p.title == '2. Problem 2');
      expect(p2.topic, 'Graphs'); // DFS, not "Binary Search"
      expect(p2.difficulty, 'EASY');
      expect(p2.url, 'https://leetcode.com/problems/problem-2/');
      expect(p2.notes, contains('Acceptance: 50.5%'));
      expect(problems.firstWhere((p) => p.title == '1. Problem 1').topic, 'Dynamic Programming');
      expect(problems.firstWhere((p) => p.title == '3. Problem 3').notes, contains('LeetCode Premium'));

      final again = await ApasDsaService(db: db, client: client).sync(limit: 500);
      expect(again.added, 0);
    });

    test('falls back to the 100+ problem offline bank when LeetCode is unreachable', () async {
      final client = MockClient((_) async => throw const FeedException('offline'));
      final result = await ApasDsaService(db: db, client: client).sync(limit: 500);
      expect(result.fetch.fromNetwork, isFalse);
      expect(ApasDsaService.offlineBank.length, greaterThanOrEqualTo(100));
      expect(result.added, ApasDsaService.offlineBank.length);
      final topics = (await db.getAllDSAProblems()).map((p) => p.topic).toSet();
      expect(topics, containsAll(['Arrays & Hashing', 'Strings', 'Trees', 'Dynamic Programming', 'Graphs', 'Backtracking', 'Greedy']));
      expect(ApasDsaService.offlineBank.map((p) => p.slug).toSet().length, ApasDsaService.offlineBank.length);
    });

    test('topicForTags prefers specific categories', () {
      expect(ApasDsaService.topicForTags(['array', 'hash-table']), 'Arrays & Hashing');
      expect(ApasDsaService.topicForTags(['tree', 'depth-first-search', 'binary-tree']), 'Trees');
      expect(ApasDsaService.topicForTags(['array', 'bit-manipulation']), 'Math & Bit Manipulation');
      expect(ApasDsaService.topicForTags(['hash-table', 'math', 'string']), 'Strings');
    });
  });

  group('SalaryParser', () {
    test('annualizes and normalizes common formats', () {
      expect(SalaryParser.parse(r'$120k – $160k')!.mid, 140000);
      expect(SalaryParser.parse(r'$90 - $150 /hour')!.max, 150 * 2080);
      expect(SalaryParser.parse('USD 95,000')!.max, 95000);
      expect(SalaryParser.parse('€60k')!.currency, 'EUR');
      expect(SalaryParser.parse('Competitive'), isNull);
    });
  });

  group('Habits', () {
    test('streak counts back from today, or yesterday if today is open', () {
      final today = DateTime(2026, 9, 29);
      final days = {DateTime(2026, 9, 26), DateTime(2026, 9, 27), DateTime(2026, 9, 28)};
      expect(habitStreak(days, today: today), 3);
      expect(habitStreak({...days, today}, today: today), 4);
      expect(habitStreak({DateTime(2026, 9, 20)}, today: today), 0);
    });

    test('setHabitDone is idempotent per day and cascades on delete', () async {
      final repo = HabitRepository(db);
      await repo.addHabit('LeetCode');
      final habit = (await db.select(db.habits).get()).single;
      final day = DateTime(2026, 9, 29, 15, 30);
      await repo.setDone(habit.id, day, true);
      await repo.setDone(habit.id, day, true);
      expect(await db.select(db.habitLogs).get(), hasLength(1));
      await repo.deleteHabit(habit.id);
      expect(await db.select(db.habitLogs).get(), isEmpty);
    });

    test('reflection upserts one row per day', () async {
      final repo = HabitRepository(db);
      await repo.saveReflection(day: DateTime(2026, 9, 29, 9), mood: 4, wins: 'Shipped');
      await repo.saveReflection(day: DateTime(2026, 9, 29, 22), mood: 5, wins: 'Shipped v2');
      final rows = await db.select(db.dailyReflections).get();
      expect(rows.single.mood, 5);
      expect(rows.single.wins, 'Shipped v2');
    });
  });
}

class _FakeProvider extends JobProvider {
  final List<RawJobItem> items;
  _FakeProvider(this.items);

  @override
  String get providerId => 'FAKE';
  @override
  String get providerName => 'Fake';

  @override
  Future<JobFetchResult> fetch({String? query, String? location, bool remoteOnly = false}) async =>
      JobFetchResult(items, [SourceStatus(sourceId: providerId, label: providerName, itemCount: items.length)]);
}

class _FailingProvider extends JobProvider {
  @override
  String get providerId => 'DOWN';
  @override
  String get providerName => 'Down';

  @override
  Future<JobFetchResult> fetch({String? query, String? location, bool remoteOnly = false}) async => throw Exception('boom');
}
