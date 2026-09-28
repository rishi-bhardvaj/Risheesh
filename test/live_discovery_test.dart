import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/features/freelance/services/freelance_lead_discovery_service.dart';
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

  group('Freelance Lead Discovery Service Tests', () {
    test('Discovers and syncs new freelance leads into Drift database', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'remoteok.com') {
          return http.Response(
            jsonEncode([
              {'legal': 'disclaimer'},
              {
                'id': 101,
                'position': 'Flutter Mobile Developer Contract',
                'company': 'Apex Global',
                'url': 'https://remoteok.com/job/101',
                'description': '<p>We need a Flutter contractor for 3 months</p>',
                'tags': ['flutter', 'mobile'],
                'salary_min': 5000,
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('', 404);
      });

      final service = FreelanceLeadDiscoveryService(db: db, client: mockClient);
      final result = await service.discoverAndSyncLeads(query: 'flutter');

      expect(result.totalDiscovered, greaterThanOrEqualTo(1));
      expect(result.newLeadsSaved, greaterThanOrEqualTo(1));

      final savedLeads = await db.getAllFreelanceLeads();
      expect(savedLeads.length, equals(result.newLeadsSaved));

      // Re-run discovery: should detect duplicates and save 0 new
      final secondResult = await service.discoverAndSyncLeads(query: 'flutter');
      expect(secondResult.newLeadsSaved, equals(0));
      expect(secondResult.duplicatesSkipped, greaterThanOrEqualTo(1));
    });
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
      final service = ApasDsaService(db: db);
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
