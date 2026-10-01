import 'dart:convert';
import 'package:career_core/career_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../db/server_store.dart';

class ApiRouter {
  final ServerStore store;
  final RelevanceEngine engine;
  static const _uuid = Uuid();

  ApiRouter({
    required this.store,
    RelevanceEngine? engine,
  }) : engine = engine ?? const RelevanceEngine();

  Router get router {
    final r = Router();

    // Health
    r.get('/healthz', (Request req) => Response.ok('{"ok":true}', headers: {'content-type': 'application/json'}));

    // Auth & Devices
    r.post('/api/v1/auth/bootstrap', (Request req) async {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final code = body['setupCode']?.toString();
      final deviceName = body['deviceName']?.toString() ?? 'Mobile App';

      if (code == null || code != store.currentSetupCode) {
        return Response(401, body: '{"error":{"code":"INVALID_SETUP_CODE","message":"Invalid setup code"}}', headers: {'content-type': 'application/json'});
      }

      final deviceId = _uuid.v4();
      final accessToken = _uuid.v4();
      final refreshToken = _uuid.v4();

      store.devices[deviceId] = DeviceRecord(
        id: deviceId,
        kind: 'APP',
        name: deviceName,
        refreshTokenHash: ServerStore.hash(refreshToken),
        createdAt: DateTime.now(),
        lastHeartbeatAt: DateTime.now(),
      );
      store.activeAccessTokens[ServerStore.hash(accessToken)] = deviceId;
      store.currentSetupCode = null; // one-time use

      return Response.ok(jsonEncode({
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresIn': 900,
      }), headers: {'content-type': 'application/json'});
    });

    r.post('/api/v1/devices/pairing-codes', (Request req) async {
      final code = '123456';
      store.pairingCodes[code] = (code, DateTime.now().add(const Duration(minutes: 10)));
      return Response.ok(jsonEncode({
        'code': code,
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      }), headers: {'content-type': 'application/json'});
    });

    r.post('/api/v1/extension/auth', (Request req) async {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final code = body['code']?.toString();
      final deviceName = body['deviceName']?.toString() ?? 'Chrome Extension';

      if (code == null || !store.pairingCodes.containsKey(code)) {
        return Response(401, body: '{"error":{"code":"INVALID_PAIRING_CODE","message":"Pairing code invalid or expired"}}', headers: {'content-type': 'application/json'});
      }

      final deviceId = _uuid.v4();
      final accessToken = _uuid.v4();
      final refreshToken = _uuid.v4();

      store.devices[deviceId] = DeviceRecord(
        id: deviceId,
        kind: 'EXTENSION',
        name: deviceName,
        refreshTokenHash: ServerStore.hash(refreshToken),
        createdAt: DateTime.now(),
        lastHeartbeatAt: DateTime.now(),
      );
      store.activeAccessTokens[ServerStore.hash(accessToken)] = deviceId;
      store.pairingCodes.remove(code);

      return Response.ok(jsonEncode({
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresIn': 900,
      }), headers: {'content-type': 'application/json'});
    });

    r.get('/api/v1/extension/config', (Request req) async {
      return Response.ok(jsonEncode({
        'policy': {
          'linkedin': {'autoRefreshAllowed': false, 'domExtractionAllowed': false},
          'naukri': {'autoRefreshAllowed': false, 'domExtractionAllowed': false},
          'ats': {'autoRefreshAllowed': true, 'domExtractionAllowed': true},
        },
      }), headers: {'content-type': 'application/json'});
    });

    // Ingestion
    r.post('/api/v1/jobs/batch-ingest', (Request req) async {
      final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
      final rawList = body['jobs'] as List? ?? const [];
      var accepted = 0;
      var dupes = 0;

      final dedup = JobDeduplicator()..addAll(store.jobs);

      for (final item in rawList) {
        if (item is! Map<String, dynamic>) continue;
        final norm = NormalizedJob.fromRaw(
          id: _uuid.v4(),
          rawTitle: item['title']?.toString() ?? '',
          rawCompany: item['company']?.toString() ?? '',
          rawLocation: item['location']?.toString(),
          rawDescription: item['description']?.toString(),
          rawUrl: item['url']?.toString(),
          rawSalary: item['salary']?.toString(),
          rawEmploymentType: item['employmentType']?.toString(),
          rawSkills: (item['skills'] as List?)?.join(', '),
          source: item['source']?.toString() ?? 'extension',
          atsProvider: item['atsProvider']?.toString(),
          externalId: item['externalId']?.toString(),
        );

        if (dedup.check(norm).isDuplicate) {
          dupes++;
          continue;
        }

        dedup.add(norm);
        store.jobs.add(norm);
        accepted++;

        // Evaluate relevance if profile present
        if (store.activeProfile != null) {
          final eval = await engine.evaluate(job: norm, candidate: store.activeProfile!);
          store.jobMatches[norm.id] = eval;
          if (eval.isPassed) {
            store.events.add({
              'id': store.events.length + 1,
              'type': 'job.matched',
              'payload': {'jobId': norm.id, 'score': eval.score, 'tier': eval.tier.name},
            });
          }
        }
      }

      return Response.ok(jsonEncode({
        'accepted': accepted,
        'duplicates': dupes,
        'total': rawList.length,
      }), headers: {'content-type': 'application/json'});
    });

    // Job Feeds
    r.get('/api/v1/jobs/recommended', (Request req) async {
      final list = store.jobs.where((j) {
        final eval = store.jobMatches[j.id];
        return eval != null && (eval.tier == RelevanceTier.highlyRelevant || eval.tier == RelevanceTier.relevant);
      }).map((j) {
        final eval = store.jobMatches[j.id];
        return {
          'id': j.id,
          'title': j.title,
          'company': j.company,
          'location': j.location,
          'score': eval?.score ?? 0,
          'tier': eval?.tier.name ?? '',
          'explanation': eval?.explainability.toJson(),
        };
      }).toList();

      return Response.ok(jsonEncode({'jobs': list}), headers: {'content-type': 'application/json'});
    });

    r.get('/api/v1/jobs/review', (Request req) async {
      final list = store.jobs.where((j) {
        final eval = store.jobMatches[j.id];
        return eval != null && eval.tier == RelevanceTier.possibleMatch;
      }).map((j) => {'id': j.id, 'title': j.title, 'company': j.company}).toList();

      return Response.ok(jsonEncode({'jobs': list}), headers: {'content-type': 'application/json'});
    });

    r.get('/api/v1/status', (Request req) async {
      return Response.ok(jsonEncode({
        'totalJobs': store.jobs.length,
        'evaluatedJobs': store.jobMatches.length,
        'devices': store.devices.length,
      }), headers: {'content-type': 'application/json'});
    });

    return r;
  }
}
