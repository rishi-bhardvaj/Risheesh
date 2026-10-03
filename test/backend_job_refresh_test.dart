import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/core/network/api_client.dart';
import 'package:career_os/features/career/providers/career_providers.dart';

Map<String, dynamic> _job(String id, {String? url, String title = 'Backend Engineer', num score = 80}) => {
      'id': id,
      'external_id': 'ext-$id',
      'title': title,
      'company': 'Acme',
      'location': 'Bengaluru, India',
      'url': url ?? 'https://jobs.example.com/$id',
      'source': 'Greenhouse',
      'skills': ['Java', 'PostgreSQL'],
      'match_score': score,
      'match_reason': 'Role: Backend',
      'status': 'OPEN',
      'is_saved': false,
      'discovered_at': '2026-10-01T10:00:00.000Z',
      'created_at': '2026-10-01T10:00:00.000Z',
      'updated_at': '2026-10-01T10:00:00.000Z',
    };

http.Response _page(List<Map<String, dynamic>> items, {int page = 1, int totalPages = 1}) => http.Response(
      jsonEncode({
        'success': true,
        'data': items,
        'pagination': {'page': page, 'limit': 100, 'total': items.length, 'totalPages': totalPages},
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  CareerRepository repoWith(MockClientHandler handler) =>
      CareerRepository(db, apiClient: ApiClient(client: MockClient(handler), baseUrl: 'http://localhost:8080'));

  test('reads the real backend envelope, asks only for OPEN jobs, follows pagination', () async {
    final seen = <Map<String, String>>[];
    final repo = repoWith((req) async {
      seen.add(req.url.queryParameters);
      final page = int.parse(req.url.queryParameters['page']!);
      return page == 1 ? _page([_job('a'), _job('b')], page: 1, totalPages: 2) : _page([_job('c')], page: 2, totalPages: 2);
    });

    final result = await repo.refreshJobsFromBackend();

    expect(result.ok, isTrue);
    expect((result.fetched, result.inserted), (3, 3));
    expect(seen.map((q) => q['page']), ['1', '2']);
    expect(seen.every((q) => q['status'] == 'OPEN' && q['limit'] == '100'), isTrue);
    expect((await db.getAllJobs()).length, 3);
    final local = await db.getJobById('a');
    expect(local!.atsProvider, 'GREENHOUSE'); // lets the Jobs screen recognise synced jobs
    expect(local.skills, 'Java, PostgreSQL');
    expect(local.matchScore, 80);
  });

  test('is idempotent and never overwrites local saved state, notes or on-device score', () async {
    final repo = repoWith((_) async => _page([_job('a', score: 90)]));
    await repo.refreshJobsFromBackend();

    await db.toggleJobSaved('a', true);
    await (db.update(db.jobs)..where((j) => j.id.equals('a'))).write(
      const JobsCompanion(notes: Value('apply friday'), matchScore: Value(42)),
    );

    final again = await repo.refreshJobsFromBackend(); // backend still says 90, not saved
    expect((again.inserted, again.updated), (0, 1));
    final job = await db.getJobById('a');
    expect(job!.isSaved, isTrue);
    expect(job.notes, 'apply friday');
    expect(job.matchScore, 42);
    expect((await db.getAllJobs()).length, 1);
  });

  test('applies backend content changes to existing jobs', () async {
    await repoWith((_) async => _page([_job('a')])).refreshJobsFromBackend();
    await repoWith((_) async => _page([_job('a', title: 'Backend Engineer (Java)')])).refreshJobsFromBackend();
    expect((await db.getJobById('a'))!.title, 'Backend Engineer (Java)');
  });

  test('does not duplicate a job already cached locally under another id (same URL)', () async {
    final now = DateTime.now();
    await db.insertJob(JobsCompanion.insert(
      id: 'local-copy',
      title: 'Backend Engineer',
      company: 'Acme',
      url: const Value('https://jobs.example.com/a'),
      source: const Value('Greenhouse'),
      discoveredAt: Value(now),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
    final result = await repoWith((_) async => _page([_job('a')])).refreshJobsFromBackend();
    expect((result.inserted, result.skipped), (0, 1));
    expect((await db.getAllJobs()).length, 1);
  });

  test('backend down: never throws, reports the error, cached jobs stay available', () async {
    await repoWith((_) async => _page([_job('a')])).refreshJobsFromBackend();

    final down = await repoWith((_) async => http.Response('boom', 503)).refreshJobsFromBackend();
    expect(down.ok, isFalse);
    expect(down.fetched, 0);

    final unreachable = await repoWith((_) async => throw http.ClientException('no route')).refreshJobsFromBackend();
    expect(unreachable.ok, isFalse);

    expect((await db.getAllJobs()).length, 1);
  });

  test('without an ApiClient it is a safe no-op', () async {
    final result = await CareerRepository(db).refreshJobsFromBackend();
    expect(result.ok, isFalse);
    expect(result.fetched, 0);
  });

  test('legacy {data: {items}} shape and syncJobsFromBackend wrapper still work', () async {
    final repo = repoWith((_) async => http.Response(
          jsonEncode({'success': true, 'data': {'items': [_job('legacy')]}}),
          200,
          headers: {'content-type': 'application/json'},
        ));
    expect(await repo.syncJobsFromBackend(), 1);
    expect(await db.getJobById('legacy'), isNotNull);
  });

  test('toggleJobSaved calls the backend save/unsave routes that actually exist', () async {
    final paths = <String>[];
    final repo = repoWith((req) async {
      paths.add('${req.method} ${req.url.path}');
      return http.Response(jsonEncode({'success': true, 'data': {}}), 200, headers: {'content-type': 'application/json'});
    });
    await repo.refreshJobsFromBackend(); // no-op for paths but seeds nothing
    paths.clear();
    await db.insertJob(JobsCompanion.insert(id: 'j1', title: 'T', company: 'C'));
    await repo.toggleJobSaved('j1', true);
    await repo.toggleJobSaved('j1', false);
    expect(paths, ['POST /api/v1/jobs/j1/save', 'POST /api/v1/jobs/j1/unsave']);
  });
}
