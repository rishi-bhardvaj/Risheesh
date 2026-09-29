import 'dart:convert';

import 'package:career_os/core/ai/ai_clients.dart';
import 'package:career_os/core/ai/ai_keys.dart';
import 'package:career_os/core/ai/ai_service.dart';
import 'package:career_os/core/ai/document_service.dart';
import 'package:career_os/core/database/app_database.dart';
import 'package:career_os/features/career/presentation/applications_view.dart';
import 'package:career_os/features/career/presentation/live_jobs_view.dart';
import 'package:career_os/features/career/services/resume_text_extractor.dart';
import 'package:career_os/features/freelance/business/business_discovery_service.dart';
import 'package:career_os/features/freelance/business/website_inspector.dart';
import 'package:career_os/features/freelance/providers/freelance_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

String _page({String head = '<meta name="viewport" content="width=device-width">', String body = '', int year = 2026}) =>
    '<html><head><title>Acme</title>$head</head><body>${body.isEmpty ? 'Quality products since 1998. ' * 40 : body}'
    '<footer>© $year Acme</footer></body></html>';

void main() {
  group('WebsiteInspector', () {
    WebsiteInspector inspector(Map<String, http.Response> pages) => WebsiteInspector(
          client: MockClient((req) async => pages[req.url.host] ?? (throw Exception('Failed host lookup'))),
        );

    test('classifies Shopify, social-only, parked, weak and good sites', () async {
      final i = inspector({
        'shop.example': http.Response(_page(body: '<script src="https://cdn.shopify.com/s/x.js"></script>'), 200, headers: {'x-shopid': '42'}),
        'parked.example': http.Response('<html><body>This domain is for sale</body></html>', 200),
        'weak.example': http.Response(_page(head: '', body: 'Welcome', year: 2019), 200),
        'good.example': http.Response(_page(), 200),
        'gone.example': http.Response('nope', 404),
      });
      expect((await i.inspect('shop.example')).presence, WebPresence.shopify);
      expect((await i.inspect('https://www.instagram.com/acme')).presence, WebPresence.noWebsite);
      expect((await i.inspect(null)).presence, WebPresence.noWebsite);
      expect((await i.inspect('parked.example')).presence, WebPresence.needsWebsite);
      final weak = await i.inspect('weak.example');
      expect(weak.presence, WebPresence.needsWebsite);
      expect(weak.notes.join(' '), contains('mobile'));
      expect((await i.inspect('good.example')).presence, WebPresence.hasWebsite);
      expect((await i.inspect('gone.example')).notes.single, contains('404'));
      expect((await i.inspect('dead.example')).notes.single, contains('does not resolve'));
    });
  });

  group('ClaudeClient.research', () {
    test('resumes pause_turn, collects sources, returns the strict tool input', () async {
      final bodies = <Map<String, dynamic>>[];
      final headers = <Map<String, String>>[];
      var call = 0;
      final client = MockClient((req) async {
        bodies.add(jsonDecode(req.body) as Map<String, dynamic>);
        headers.add(req.headers);
        call++;
        if (call == 1) {
          return _json({
            'stop_reason': 'pause_turn',
            'content': [
              {'type': 'server_tool_use', 'id': 's1', 'name': 'web_search', 'input': {'query': 'x'}},
              {
                'type': 'web_search_tool_result',
                'tool_use_id': 's1',
                'content': [
                  {'type': 'web_search_result', 'url': 'https://indiamart.com/acme', 'title': 'Acme Industries'},
                ],
              },
            ],
          });
        }
        return _json({
          'stop_reason': 'tool_use',
          'content': [
            {'type': 'tool_use', 'id': 't1', 'name': 'submit', 'input': {'items': ['a']}},
          ],
        });
      });
      final result = await ClaudeClient('sk-ant-test', client: client).research(
        system: 'sys',
        prompt: 'find',
        resultTool: 'submit',
        resultDescription: 'd',
        resultSchema: {'type': 'object'},
      );
      expect(result.data['items'], ['a']);
      expect(result.sources.single.url, 'https://indiamart.com/acme');
      expect(result.webSearches, 1);
      expect(bodies.first['model'], 'claude-opus-5');
      expect(bodies.first['fallbacks'], 'default');
      expect((bodies.first['tools'] as List).first['type'], 'web_search_20260209');
      expect(headers.first['anthropic-beta'], 'server-side-fallback-2026-07-01');
      // Second request echoes the paused assistant turn unchanged.
      expect((bodies[1]['messages'] as List).length, 2);
      expect((bodies[1]['messages'] as List).last['role'], 'assistant');
    });

    test('surfaces API errors and refusals as AiException', () async {
      final bad = ClaudeClient('k', client: MockClient((_) async => _json({'error': {'message': 'invalid x-api-key'}}, 401)));
      expect(() => bad.complete('hi'), throwsA(isA<AiException>().having((e) => e.isAuth, 'isAuth', true)));
      final refused = ClaudeClient('k', client: MockClient((_) async => _json({'stop_reason': 'refusal', 'content': []})));
      expect(() => refused.complete('hi'), throwsA(isA<AiException>()));
    });
  });

  group('Gemini & Nemotron', () {
    test('Gemini picks the newest stable pro model and skips thought parts', () async {
      final client = MockClient((req) async {
        if (req.url.path.endsWith('/models')) {
          return _json({
            'models': [
              {'name': 'models/gemini-2.5-flash', 'supportedGenerationMethods': ['generateContent']},
              {'name': 'models/gemini-3.0-pro', 'supportedGenerationMethods': ['generateContent']},
              {'name': 'models/gemini-3.5-pro-preview', 'supportedGenerationMethods': ['generateContent']},
              {'name': 'models/gemini-3.0-pro-tts', 'supportedGenerationMethods': ['generateContent']},
              {'name': 'models/text-embedding-004', 'supportedGenerationMethods': ['embedContent']},
            ],
          });
        }
        return _json({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'thinking…', 'thought': true},
                  {'text': '# Proposal'},
                ],
              },
            },
          ],
        });
      });
      expect(await GeminiClient.pickModel('k', client: client), 'gemini-3.0-pro');
      expect(await GeminiClient('k', client: client).generate('x'), '# Proposal');
    });

    test('Nemotron strips <think> and AiService falls back to Claude without an NVIDIA key', () async {
      final nvidia = MockClient((_) async => _json({
            'choices': [
              {'message': {'content': '<think>hmm</think>\nHello there'}},
            ],
          }));
      expect(await NemotronClient('nvapi-x', client: nvidia).chat('hi'), 'Hello there');

      final claudeOnly = MockClient((req) async {
        expect(req.url.host, 'api.anthropic.com');
        return _json({
          'stop_reason': 'end_turn',
          'content': [
            {'type': 'text', 'text': 'From Claude'},
          ],
        });
      });
      final ai = AiService(const AiKeys().copyWith(AiProvider.claude, 'sk-ant-x'), client: claudeOnly);
      expect(await ai.quick('hi'), 'From Claude');
      expect(() => ai.gemini, throwsA(isA<AiMissingKeyException>()));
    });

    test('required keys are Claude and Gemini', () {
      var keys = const AiKeys().copyWith(AiProvider.claude, 'a');
      expect(keys.hasRequired, isFalse);
      keys = keys.copyWith(AiProvider.gemini, 'b');
      expect(keys.hasRequired, isTrue);
      expect(keys.copyWith(AiProvider.gemini, '  ').hasRequired, isFalse);
    });
  });

  group('BusinessDiscoveryService', () {
    test('keeps ≥ ₹1 Cr businesses with no/weak sites, verifies presence, dedupes', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      Map<String, dynamic> biz(String name, double? turnover, String? site, {String? phone}) => {
            'name': name,
            'industry': 'Textiles',
            'city': 'Surat',
            'country': 'India',
            'estimated_annual_turnover_inr': turnover,
            'turnover_evidence': 'IndiaMART: Annual Turnover 5 - 25 Cr',
            'turnover_source_url': 'https://indiamart.com/$name',
            'website_url': site,
            'web_presence_notes': '',
            'phone': phone,
            'email': null,
            'address': null,
            'links': [
              {'label': 'IndiaMART', 'url': 'https://indiamart.com/$name'},
            ],
            'pitch_angle': 'Sells wholesale only through IndiaMART.',
          };
      final claudeHttp = MockClient((_) async => _json({
            'stop_reason': 'tool_use',
            'content': [
              {
                'type': 'tool_use',
                'id': 't',
                'name': 'submit_businesses',
                'input': {
                  'businesses': [
                    biz('NoSite Textiles', 5e7, null, phone: '+91 98765 43210'),
                    biz('Shopify Sarees', 2e7, 'shop.example'),
                    biz('Tiny Traders', 4e6, null),
                    biz('Modern Mills', 9e7, 'good.example'),
                    biz('NoSite Textiles', 5e7, null),
                  ],
                },
              },
            ],
          }));
      final inspector = WebsiteInspector(
        client: MockClient((req) async => switch (req.url.host) {
              'shop.example' => http.Response(_page(body: 'cdn.shopify.com'), 200),
              'good.example' => http.Response(_page(), 200),
              _ => http.Response('', 404),
            }),
      );
      final service = BusinessDiscoveryService(db: db, claude: ClaudeClient('k', client: claudeHttp), inspector: inspector);
      final result = await service.discover(const BusinessSearchRequest());

      expect(result.found, 5);
      expect(result.saved, 2);
      expect(result.skippedBelowCrore, 1);
      expect(result.skippedGoodWebsite, 1);
      expect(result.duplicates, 1);
      final leads = await db.getBusinessLeads();
      final noSite = leads.firstWhere((l) => l.name == 'NoSite Textiles');
      expect(noSite.webPresence, 'NO_WEBSITE');
      expect(noSite.needScore, greaterThan(leads.firstWhere((l) => l.name == 'Shopify Sarees').needScore));
      expect(leads.firstWhere((l) => l.name == 'Shopify Sarees').webPresence, 'SHOPIFY');

      // Second run: same names are skipped as duplicates.
      final again = await service.discover(const BusinessSearchRequest());
      expect(again.saved, 0);
    });

    test('formatInr uses crore / lakh', () {
      expect(formatInr(4.5e7), '₹4.5 Cr');
      expect(formatInr(2.5e8), '₹25 Cr');
      expect(formatInr(8e6), '₹80 L');
    });
  });

  group('Filters', () {
    final now = DateTime(2026, 9, 29, 12);
    Job job(String id, {String title = 'Engineer', String? location, bool saved = false, DateTime? posted, String? skills}) => Job(
          id: id,
          title: title,
          company: 'Co',
          location: location,
          skills: skills,
          isSaved: saved,
          postedDate: posted,
          discoveredAt: posted ?? now.subtract(const Duration(days: 10)),
          createdAt: now,
          updatedAt: now,
        );
    final profile = UserProfile(
      id: 'u',
      name: 'Me',
      currentRole: 'Flutter Developer',
      experienceYears: 4,
      skills: 'Flutter, Dart, Riverpod, Firebase',
      remotePreference: 'remote',
      createdAt: now,
      updatedAt: now,
    );

    test('filterJobs: best match, remote, new, saved, query', () {
      final jobs = [
        job('a', title: 'Senior Flutter Engineer', location: 'Remote', skills: 'Flutter, Dart, Riverpod'),
        job('b', title: 'Accountant', location: 'Mumbai'),
        job('c', title: 'Backend Engineer', location: 'Remote', saved: true, posted: now.subtract(const Duration(days: 1))),
      ];
      List<String> ids(JobFilter f, [String q = '']) => filterJobs(jobs, profile, filter: f, query: q, now: now).map((e) => e.$1.id).toList();
      expect(ids(JobFilter.all).first, 'a'); // sorted by match
      expect(ids(JobFilter.bestMatch), ['a']);
      expect(ids(JobFilter.remote).toSet(), {'a', 'c'});
      expect(ids(JobFilter.fresh), ['c']);
      expect(ids(JobFilter.saved), ['c']);
      expect(ids(JobFilter.all, 'account'), ['b']);
    });

    test('filterApplications: each bucket', () {
      JobApplication app(String id, String status, {DateTime? followUp}) =>
          JobApplication(id: id, company: 'C', role: 'R', status: status, followUpDate: followUp, createdAt: now, updatedAt: now);
      final apps = [
        app('1', 'applied', followUp: now.subtract(const Duration(days: 1))),
        app('2', 'interview'),
        app('3', 'offer'),
        app('4', 'rejected', followUp: now.subtract(const Duration(days: 1))),
        app('5', 'screening', followUp: now.add(const Duration(days: 3))),
      ];
      List<String> ids(AppFilter f) => filterApplications(apps, f, now: now).map((a) => a.id).toList()..sort();
      expect(ids(AppFilter.all), ['1', '2', '3', '4', '5']);
      expect(ids(AppFilter.active), ['1', '5']);
      expect(ids(AppFilter.interviews), ['2']);
      expect(ids(AppFilter.offers), ['3']);
      expect(ids(AppFilter.followUp), ['1']); // closed apps and future dates excluded
      expect(ids(AppFilter.closed), ['4']);
    });

    test('filterBusinessLeads: presence, pipeline split, search', () {
      BusinessLead lead(String id, String presence, String status, {String name = 'Acme'}) => BusinessLead(
            id: id,
            name: name,
            country: 'India',
            webPresence: presence,
            needScore: 50,
            status: status,
            discoveredAt: now,
            updatedAt: now,
            city: 'Pune',
          );
      final all = [
        lead('1', 'NO_WEBSITE', 'NEW'),
        lead('2', 'SHOPIFY', 'NEW', name: 'Saree House'),
        lead('3', 'NO_WEBSITE', 'CONTACTED'),
      ];
      expect(filterBusinessLeads(all).map((b) => b.id), ['1', '2']);
      expect(filterBusinessLeads(all, presence: WebPresence.shopify).map((b) => b.id), ['2']);
      expect(filterBusinessLeads(all, pipeline: true).map((b) => b.id), ['3']);
      expect(filterBusinessLeads(all, query: 'saree').map((b) => b.id), ['2']);
    });
  });

  group('Documents', () {
    const md = '# Proposal for Acme\n\n## Where you are today\nYou sell **₹5 Cr** a year via IndiaMART.\n\n- New catalogue site\n- WhatsApp ordering\n\n1. Discovery\n2. Build';

    test('DOCX round-trips through the resume extractor', () {
      final text = DocxTextExtractor.extract(DocumentService.markdownToDocx(md));
      expect(text, contains('Proposal for Acme'));
      expect(text, contains('You sell ₹5 Cr a year via IndiaMART.'));
      expect(text, contains('• New catalogue site'));
    });

    test('PDF round-trips through the resume extractor', () async {
      final bytes = await DocumentService.markdownToPdf(md, title: 'Proposal');
      final text = PdfTextExtractor(bytes).extract();
      expect(text, contains('Proposal for Acme'));
      expect(text, contains('WhatsApp ordering'));
      // No system Roboto in tests, so ₹ falls back to "Rs."
      expect(text, contains('Rs. 5 Cr'));
    });
  });
}
