import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/features/career/data/job_providers/public_api_job_provider.dart';
import 'package:career_os/features/track/services/apas_dsa_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Job Providers Tests (Greenhouse & Lever)', () {
    test('GreenhouseJobProvider parses jobs JSON correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'jobs': [
              {
                'id': 12345,
                'title': 'Senior Software Engineer, Platform',
                'absolute_url': 'https://boards.greenhouse.io/airbnb/jobs/12345',
                'updated_at': '2026-09-20T10:00:00Z',
                'location': {'name': 'San Francisco, CA / Remote'},
                'content': '<p>Join our core infrastructure team</p>',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = GreenhouseJobProvider(
        boardTokens: ['airbnb'],
        client: mockClient,
      );

      final jobs = await provider.searchJobs();
      expect(jobs.length, equals(1));
      expect(jobs.first.company.toLowerCase(), equals('airbnb'));
      expect(jobs.first.title, equals('Senior Software Engineer, Platform'));
      expect(jobs.first.atsProvider, equals('GREENHOUSE'));
      expect(jobs.first.url, contains('greenhouse.io'));
    });

    test('LeverJobProvider parses postings JSON correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': 'lever-job-1',
              'text': 'Lead Mobile Architect (Flutter/React Native)',
              'hostedUrl': 'https://jobs.lever.co/palantir/lever-job-1',
              'createdAt': 1727000000000,
              'categories': {
                'location': 'Los Gatos, CA',
                'allLocations': ['Los Gatos, CA', 'Remote'],
              },
              'descriptionPlain': 'Architect scalable mobile applications.',
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = LeverJobProvider(
        organizations: ['palantir'],
        client: mockClient,
      );

      final jobs = await provider.searchJobs();
      expect(jobs.length, equals(1));
      expect(jobs.first.company.toLowerCase(), equals('palantir'));
      expect(jobs.first.title, contains('Mobile Architect'));
      expect(jobs.first.atsProvider, equals('LEVER'));
      expect(jobs.first.url, contains('lever.co'));
    });
  });

  group('ApasDsaService Offline & Sync Tests', () {
    test('Returns curated bank and syncs to database when offline', () async {
      // No network in tests: every LeetCode page fails, so the offline bank is used.
      final service = ApasDsaService(db: db, client: MockClient((_) async => http.Response('offline', 503)));
      final count = await service.syncProblemsToDatabase(limit: 10);

      expect(count, equals(10));
      final problems = await db.getAllDSAProblems();
      expect(problems.length, equals(10));
      expect(problems.first.platform, contains('LeetCode'));

      // Running sync again shouldn't duplicate existing problems
      final secondCount = await service.syncProblemsToDatabase(limit: 10);
      expect(secondCount, equals(0));
    });
  });
}
