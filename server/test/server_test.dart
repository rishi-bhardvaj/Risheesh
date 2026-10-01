import 'dart:convert';
import 'package:career_core/career_core.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../lib/db/server_store.dart';
import '../lib/http/api_router.dart';

void main() {
  group('Server Core & API Tests (M9)', () {
    late ServerStore store;
    late ApiRouter api;

    setUp(() {
      store = ServerStore();
      api = ApiRouter(
        store: store,
        engine: RelevanceEngine(
          matchingProvider: const FakeMatchingProvider(),
          embeddingProvider: FakeEmbeddingProvider(),
        ),
      );
    });

    test('healthz returns ok:true', () async {
      final req = Request('GET', Uri.parse('http://localhost/healthz'));
      final res = await api.router(req);
      expect(res.statusCode, 200);
      final body = jsonDecode(await res.readAsString());
      expect(body['ok'], true);
    });

    test('bootstrap authentication with setup code exchanges for tokens', () async {
      final req = Request(
        'POST',
        Uri.parse('http://localhost/api/v1/auth/bootstrap'),
        body: jsonEncode({'setupCode': 'BOOT1234', 'deviceName': 'Test Phone'}),
        headers: {'content-type': 'application/json'},
      );
      final res = await api.router(req);
      expect(res.statusCode, 200);
      final body = jsonDecode(await res.readAsString());
      expect(body['accessToken'], isNotEmpty);
      expect(body['refreshToken'], isNotEmpty);
      expect(store.currentSetupCode, isNull, reason: 'Setup code must be one-time use');
    });

    test('extension pairing flow with 6-digit code', () async {
      // 1. Generate pairing code
      final pairReq = Request('POST', Uri.parse('http://localhost/api/v1/devices/pairing-codes'));
      final pairRes = await api.router(pairReq);
      expect(pairRes.statusCode, 200);
      final pairBody = jsonDecode(await pairRes.readAsString());
      final code = pairBody['code'] as String;

      // 2. Extension auth using code
      final authReq = Request(
        'POST',
        Uri.parse('http://localhost/api/v1/extension/auth'),
        body: jsonEncode({'code': code, 'deviceName': 'Chrome Workstation'}),
        headers: {'content-type': 'application/json'},
      );
      final authRes = await api.router(authReq);
      expect(authRes.statusCode, 200);
      final authBody = jsonDecode(await authRes.readAsString());
      expect(authBody['accessToken'], isNotEmpty);

      // Reusing code should fail
      final reuseReq = Request(
        'POST',
        Uri.parse('http://localhost/api/v1/extension/auth'),
        body: jsonEncode({'code': code}),
        headers: {'content-type': 'application/json'},
      );
      final reuseRes = await api.router(reuseReq);
      expect(reuseRes.statusCode, 401);
    });

    test('batch ingestion dedupes and scores jobs against active candidate profile', () async {
      store.activeProfile = const CandidateProfile(
        name: 'Mobile Dev',
        currentRole: 'Flutter Developer',
        primaryRoleFamily: RoleFamily.mobile,
        experienceMonths: 36,
        primarySkills: ['Flutter', 'Dart', 'Riverpod', 'SQLite'],
      );

      final ingestReq = Request(
        'POST',
        Uri.parse('http://localhost/api/v1/jobs/batch-ingest'),
        body: jsonEncode({
          'jobs': [
            {
              'title': 'Senior Flutter Engineer',
              'company': 'Tech Corp',
              'location': 'Bengaluru',
              'skills': ['Flutter', 'Dart', 'Riverpod'],
              'url': 'https://example.com/job/1',
              'description': 'Requirements:\n• Flutter and Dart\n• Riverpod',
            },
            {
              'title': 'Enterprise Sales Executive',
              'company': 'Sales Hub',
              'location': 'Remote',
              'url': 'https://example.com/job/2',
              'description': 'Sales closing role.',
            },
            {
              // Duplicate of job 1
              'title': 'Senior Flutter Engineer',
              'company': 'Tech Corp',
              'location': 'Bengaluru',
              'url': 'https://example.com/job/1?utm_source=linkedin',
            }
          ]
        }),
        headers: {'content-type': 'application/json'},
      );

      final ingestRes = await api.router(ingestReq);
      expect(ingestRes.statusCode, 200);
      final ingestBody = jsonDecode(await ingestRes.readAsString());
      expect(ingestBody['accepted'], 2);
      expect(ingestBody['duplicates'], 1);

      // Recommended feed should only contain the relevant Flutter job, NOT the Sales job
      final recReq = Request('GET', Uri.parse('http://localhost/api/v1/jobs/recommended'));
      final recRes = await api.router(recReq);
      expect(recRes.statusCode, 200);
      final recBody = jsonDecode(await recRes.readAsString());
      final jobs = recBody['jobs'] as List;
      expect(jobs.length, 1);
      expect(jobs.first['title'], 'Senior Flutter Engineer');
    });
  });
}
