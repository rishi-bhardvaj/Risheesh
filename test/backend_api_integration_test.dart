import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:drift/native.dart';

import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/core/network/api_client.dart';
import 'package:career_os/core/network/api_exception.dart';
import 'package:career_os/core/network/dtos/job_dto.dart';
import 'package:career_os/core/network/dtos/freelance_dto.dart';
import 'package:career_os/features/career/providers/career_providers.dart';
import 'package:career_os/features/freelance/providers/freelance_providers.dart';

void main() {
  group('ApiClient Tests', () {
    test('successful GET request unwraps data payload', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/jobs');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  'id': 'job-1',
                  'title': 'Senior Flutter Engineer',
                  'company': 'Tech Corp',
                  'discovered_at': '2026-10-01T10:00:00.000Z',
                  'created_at': '2026-10-01T10:00:00.000Z',
                  'updated_at': '2026-10-01T10:00:00.000Z',
                }
              ],
              'total': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:8080');
      final result = await apiClient.get('/api/v1/jobs');

      expect(result, isA<Map<String, dynamic>>());
      expect(result['total'], 1);
      expect(result['items'].first['title'], 'Senior Flutter Engineer');
    });

    test('error response throws ApiException with statusCode and message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'message': 'Resource not found',
              'code': 'NOT_FOUND',
            }
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:8080');

      expect(
        () => apiClient.get('/api/v1/jobs/non-existent'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404).having((e) => e.message, 'message', 'Resource not found')),
      );
    });

    test('POST and PATCH requests serialize JSON bodies correctly', () async {
      String? sentBody;
      final mockClient = MockClient((request) async {
        sentBody = request.body;
        return http.Response(
          jsonEncode({'success': true, 'data': {'id': 'created-123'}}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:8080');
      final res = await apiClient.post('/api/v1/jobs', body: {'title': 'Dart Lead', 'company': 'Acme'});

      expect(res['id'], 'created-123');
      expect(sentBody, contains('Dart Lead'));
    });
  });

  group('DTO Mappings', () {
    test('JobDto parses json and creates Drift JobsCompanion', () {
      final json = {
        'id': 'uuid-1',
        'external_id': 'ext-99',
        'title': 'Staff Mobile Engineer',
        'company': 'Google',
        'location': 'Bengaluru',
        'salary': '₹40-50 LPA',
        'employment_type': 'Full-time',
        'experience_requirement': '5+ years',
        'url': 'https://careers.google.com/job/1',
        'source': 'LinkedIn',
        'description': 'Building next-gen mobile platforms',
        'skills': ['Flutter', 'Dart', 'PostgreSQL'],
        'posted_date': '2026-09-30T10:00:00.000Z',
        'discovered_at': '2026-10-01T05:00:00.000Z',
        'match_score': 95,
        'match_reason': 'Superb match for Flutter skills',
        'is_saved': true,
        'notes': 'Interview scheduled',
        'metadata': {'priority': 'high'},
        'created_at': '2026-10-01T05:00:00.000Z',
        'updated_at': '2026-10-01T05:00:00.000Z',
      };

      final dto = JobDto.fromJson(json);
      expect(dto.id, 'uuid-1');
      expect(dto.title, 'Staff Mobile Engineer');
      expect(dto.skills, ['Flutter', 'Dart', 'PostgreSQL']);
      expect(dto.isSaved, isTrue);

      final companion = dto.toCompanion();
      expect(companion.id.value, 'uuid-1');
      expect(companion.title.value, 'Staff Mobile Engineer');
      expect(companion.company.value, 'Google');
      expect(companion.skills.value, 'Flutter, Dart, PostgreSQL');
      expect(companion.isSaved.value, isTrue);
      expect(companion.matchScore.value, 95);
      expect(companion.matchTier.value, 'STRONG');
    });

    test('FreelanceLeadDto parses json and creates Drift FreelanceLeadsCompanion', () {
      final json = {
        'id': 'lead-uuid-1',
        'external_id': 'upwork-123',
        'title': 'Cross-Platform Mobile App',
        'client_name': 'Acme Corp',
        'contact_name': 'John Doe',
        'contact_info': 'john@acme.com',
        'platform': 'Upwork',
        'description': 'Develop iOS and Android app in Flutter',
        'skills': ['Flutter', 'Firebase'],
        'budget': 3500.0,
        'currency': 'USD',
        'url': 'https://upwork.com/jobs/123',
        'status': 'PROPOSAL_SENT',
        'proposal': 'Hi, I have 5 years Flutter experience',
        'notes': 'Sent proposal on Upwork',
        'created_at': '2026-10-01T05:00:00.000Z',
        'updated_at': '2026-10-01T05:00:00.000Z',
      };

      final dto = FreelanceLeadDto.fromJson(json);
      expect(dto.id, 'lead-uuid-1');
      expect(dto.title, 'Cross-Platform Mobile App');
      expect(dto.budget, 3500.0);
      expect(dto.status, 'PROPOSAL_SENT');

      final companion = dto.toCompanion();
      expect(companion.id.value, 'lead-uuid-1');
      expect(companion.title.value, 'Cross-Platform Mobile App');
      expect(companion.budget.value, 3500.0);
      expect(companion.skills.value, 'Flutter, Firebase');
      expect(companion.status.value, 'PROPOSAL_SENT');
    });
  });

  group('Repository Backend Sync', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('CareerRepository syncJobsFromBackend populates local Drift cache', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/jobs');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  'id': 'job-sync-1',
                  'title': 'Full-Stack Flutter Engineer',
                  'company': 'Awesome Tech',
                  'location': 'Remote',
                  'salary': '₹25-35 LPA',
                  'skills': ['Flutter', 'Node.js', 'PostgreSQL'],
                  'discovered_at': DateTime.now().toIso8601String(),
                  'is_saved': false,
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                }
              ],
              'total': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:8080');
      final repo = CareerRepository(db, apiClient: apiClient);

      final count = await repo.syncJobsFromBackend();
      expect(count, 1);

      final localJob = await db.getJobById('job-sync-1');
      expect(localJob, isNotNull);
      expect(localJob!.title, 'Full-Stack Flutter Engineer');
      expect(localJob.company, 'Awesome Tech');
      expect(localJob.skills, 'Flutter, Node.js, PostgreSQL');
    });

    test('FreelanceRepository syncLeadsFromBackend populates local Drift cache', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/freelance/leads');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  'id': 'lead-sync-1',
                  'title': 'E-Commerce Flutter App',
                  'client_name': 'Shop Global',
                  'platform': 'Upwork',
                  'budget': 4000.0,
                  'currency': 'USD',
                  'skills': ['Flutter', 'Stripe'],
                  'status': 'NEW_LEAD',
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                }
              ],
              'total': 1,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:8080');
      final repo = FreelanceRepository(db, apiClient: apiClient);

      final count = await repo.syncLeadsFromBackend();
      expect(count, 1);

      final localLead = await db.getLeadById('lead-sync-1');
      expect(localLead, isNotNull);
      expect(localLead!.title, 'E-Commerce Flutter App');
      expect(localLead.clientName, 'Shop Global');
      expect(localLead.budget, 4000.0);
    });

    test('CareerRepository addJob inserts into Drift and sends POST to ApiClient', () async {
      bool apiPostCalled = false;
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path == '/api/v1/jobs') {
          apiPostCalled = true;
          return http.Response(
            jsonEncode({'success': true, 'data': {'id': 'created'}}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:8080');
      final repo = CareerRepository(db, apiClient: apiClient);

      await repo.addJob(
        title: 'Lead Architect',
        company: 'Innovate Ltd',
        location: 'Hyderabad',
        salary: '₹50 LPA',
      );

      expect(apiPostCalled, isTrue);

      final allJobs = await db.getAllJobs();
      expect(allJobs.any((j) => j.title == 'Lead Architect' && j.company == 'Innovate Ltd'), isTrue);
    });

    test('FreelanceRepository addLead inserts into Drift and sends POST to ApiClient', () async {
      bool apiPostCalled = false;
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path == '/api/v1/freelance/leads') {
          apiPostCalled = true;
          return http.Response(
            jsonEncode({'success': true, 'data': {'id': 'created'}}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:8080');
      final repo = FreelanceRepository(db, apiClient: apiClient);

      final leadId = await repo.addLead(
        title: 'Custom CRM Backend',
        clientName: 'Big Enterprise',
        budget: 6000.0,
      );

      expect(apiPostCalled, isTrue);

      final localLead = await db.getLeadById(leadId);
      expect(localLead, isNotNull);
      expect(localLead!.title, 'Custom CRM Backend');
      expect(localLead.budget, 6000.0);
    });
  });
}
