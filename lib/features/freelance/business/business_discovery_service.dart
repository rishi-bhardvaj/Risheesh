import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ai/ai_clients.dart';
import '../../../core/database/app_database.dart';
import 'website_inspector.dart';

enum LeadRegion {
  india('India'),
  global('Global');

  final String label;
  const LeadRegion(this.label);
}

class BusinessSearchRequest {
  final LeadRegion region;
  final String? industry;
  final String? city;
  final int count;

  const BusinessSearchRequest({this.region = LeadRegion.india, this.industry, this.city, this.count = 10});
}

class BusinessDiscoveryResult {
  final int found;
  final int saved;
  final int skippedBelowCrore;
  final int skippedGoodWebsite;
  final int duplicates;
  final int webSearches;

  const BusinessDiscoveryResult({
    required this.found,
    required this.saved,
    required this.skippedBelowCrore,
    required this.skippedGoodWebsite,
    required this.duplicates,
    required this.webSearches,
  });

  String get summary {
    final skipped = [
      if (skippedGoodWebsite > 0) '$skippedGoodWebsite already have a good site',
      if (skippedBelowCrore > 0) '$skippedBelowCrore under ₹1 Cr',
      if (duplicates > 0) '$duplicates already saved',
    ];
    return 'Added $saved of $found businesses${skipped.isEmpty ? '' : ' · skipped ${skipped.join(', ')}'}';
  }
}

/// Finds businesses with ≥ ₹1 crore annual turnover and no / weak web
/// presence. Claude does the web research; every web-presence claim is then
/// re-checked locally by [WebsiteInspector] before anything is saved.
class BusinessDiscoveryService {
  final AppDatabase db;
  final ClaudeClient claude;
  final WebsiteInspector inspector;
  static const _uuid = Uuid();
  static const minTurnoverInr = 1e7; // ₹1 crore

  BusinessDiscoveryService({required this.db, required this.claude, WebsiteInspector? inspector})
      : inspector = inspector ?? WebsiteInspector();

  static Map<String, dynamic> _nullable(String type) => {
        'anyOf': [
          {'type': type},
          {'type': 'null'},
        ],
      };

  static final resultSchema = <String, dynamic>{
    'type': 'object',
    'additionalProperties': false,
    'required': ['businesses'],
    'properties': {
      'businesses': {
        'type': 'array',
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'required': [
            'name', 'industry', 'city', 'country', 'estimated_annual_turnover_inr', 'turnover_evidence',
            'turnover_source_url', 'website_url', 'web_presence_notes', 'phone', 'email', 'address', 'links', 'pitch_angle',
          ],
          'properties': {
            'name': {'type': 'string'},
            'industry': {'type': 'string'},
            'city': {'type': 'string'},
            'country': {'type': 'string'},
            'estimated_annual_turnover_inr': _nullable('number'),
            'turnover_evidence': {'type': 'string', 'description': 'Quote or fact that supports the turnover figure'},
            'turnover_source_url': _nullable('string'),
            'website_url': _nullable('string'),
            'web_presence_notes': {'type': 'string'},
            'phone': _nullable('string'),
            'email': _nullable('string'),
            'address': _nullable('string'),
            'links': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': ['label', 'url'],
                'properties': {
                  'label': {'type': 'string'},
                  'url': {'type': 'string'},
                },
              },
            },
            'pitch_angle': {'type': 'string', 'description': 'One sentence on why a website would pay off for them'},
          },
        },
      },
    },
  };

  static const _system = '''
You are a B2B lead researcher for an independent web developer. You find real, currently operating businesses that make at least ₹1 crore (10,000,000 INR) a year but have no proper website: no site at all, only a marketplace/social page, a Shopify store, or a weak/outdated site.

Rules:
- Only include businesses you found evidence for in search results. Never invent names, numbers, phone numbers or URLs.
- Turnover must be evidenced: directory turnover bands (IndiaMART, TradeIndia, ExportersIndia "Annual Turnover"), GST/registry filings, reported revenue, employee counts ≥ 10, multiple outlets, or large marketplace sales volume. Put the evidence in turnover_evidence and its page in turnover_source_url.
- estimated_annual_turnover_inr is the LOWER bound of the evidenced range converted to INR (1 crore = 10,000,000; USD 1 ≈ INR 88). Use null only if there is no figure at all.
- website_url is the business's own domain if one exists, else null. Marketplace/social pages go in links, not website_url.
- Only public business contact details (listed phone, business email, address). No personal data about private individuals.
- Aim for a mix: some with no website, some on Shopify, some with a weak site.''';

  String _prompt(BusinessSearchRequest req, List<String> exclude) {
    final where = [
      if (req.city != null && req.city!.trim().isNotEmpty) req.city!.trim(),
      req.region == LeadRegion.india ? 'India' : 'outside India (US, UK, UAE, EU, Australia, Singapore)',
    ].join(', ');
    return [
      'Find ${req.count} businesses in $where${req.industry != null && req.industry!.trim().isNotEmpty ? ' in the "${req.industry!.trim()}" industry' : ' across industries such as manufacturers, wholesalers, distributors, exporters, clinics, restaurant chains, retailers and D2C brands'}.',
      if (req.region == LeadRegion.india)
        'Good sources: IndiaMART / TradeIndia / ExportersIndia supplier profiles (they show "Annual Turnover" and GST), Justdial, Google Maps listings, Amazon/Flipkart seller pages.'
      else
        'Good sources: Google Maps / Yelp listings, Etsy / Amazon storefronts, trade directories, local news and company registries.',
      if (exclude.isNotEmpty) 'Skip these, already known: ${exclude.join('; ')}.',
      'When done, call submit_businesses with the results.',
    ].join('\n');
  }

  static int needScore({required WebPresence presence, required double? turnoverInr, required bool hasPhone, required bool hasEmail, required int links}) {
    final presencePts = switch (presence) {
      WebPresence.noWebsite => 45,
      WebPresence.needsWebsite => 40,
      WebPresence.shopify => 25,
      WebPresence.hasWebsite => 5,
    };
    final t = turnoverInr ?? minTurnoverInr;
    final turnoverPts = math.min(25, (10 + 7.5 * (math.log(t / minTurnoverInr) / math.ln10)).round());
    final contactPts = (hasPhone ? 10 : 0) + (hasEmail ? 5 : 0);
    final onlinePts = math.min(10, links * 3); // already selling/marketing online
    return math.min(100, presencePts + math.max(0, turnoverPts) + contactPts + onlinePts).toInt();
  }

  static String _key(String name, String? city) =>
      '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}|${(city ?? '').toLowerCase().trim()}';

  Future<BusinessDiscoveryResult> discover(BusinessSearchRequest req) async {
    final existing = await db.getBusinessLeads();
    final known = existing.map((b) => _key(b.name, b.city)).toSet();
    final research = await claude.research(
      system: _system,
      prompt: _prompt(req, existing.take(60).map((b) => b.name).toList()),
      resultTool: 'submit_businesses',
      resultDescription: 'Submit the businesses you found, with evidence.',
      resultSchema: resultSchema,
      maxSearches: 12,
    );
    final candidates = (research.data['businesses'] as List? ?? const []).whereType<Map>().map(Map<String, dynamic>.from).toList();
    final sources = jsonEncode([
      for (final s in research.sources.take(12)) {'title': s.title, 'url': s.url},
    ]);

    var belowCrore = 0, goodSite = 0, dupes = 0;
    final inserts = <BusinessLeadsCompanion>[];
    final now = DateTime.now();

    // Inspect sites a few at a time.
    final reports = <int, PresenceReport>{};
    for (var i = 0; i < candidates.length; i += 4) {
      final batch = [for (var j = i; j < math.min(i + 4, candidates.length); j++) j];
      final results = await Future.wait(batch.map((j) => inspector.inspect(candidates[j]['website_url'] as String?)));
      for (var k = 0; k < batch.length; k++) {
        reports[batch[k]] = results[k];
      }
    }

    for (var i = 0; i < candidates.length; i++) {
      final c = candidates[i];
      final name = (c['name'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      final city = (c['city'] as String?)?.trim();
      final turnover = (c['estimated_annual_turnover_inr'] as num?)?.toDouble();
      if (turnover == null || turnover < minTurnoverInr) {
        belowCrore++;
        continue;
      }
      if (!known.add(_key(name, city))) {
        dupes++;
        continue;
      }
      final report = reports[i]!;
      if (report.presence == WebPresence.hasWebsite) {
        goodSite++;
        continue;
      }
      final links = (c['links'] as List? ?? const []).whereType<Map>().toList();
      final phone = (c['phone'] as String?)?.trim();
      final email = (c['email'] as String?)?.trim();
      inserts.add(BusinessLeadsCompanion(
        id: Value(_uuid.v4()),
        name: Value(name.length > 200 ? name.substring(0, 200) : name),
        industry: Value(c['industry'] as String?),
        city: Value(city),
        country: Value((c['country'] as String?)?.trim().isNotEmpty == true ? c['country'] as String : req.region.label),
        turnoverInr: Value(turnover),
        turnoverEvidence: Value(c['turnover_evidence'] as String?),
        turnoverSourceUrl: Value(c['turnover_source_url'] as String?),
        websiteUrl: Value(report.presence == WebPresence.noWebsite ? null : (report.finalUrl ?? c['website_url'] as String?)),
        webPresence: Value(report.presence.value),
        presenceNotes: Value([...report.notes, if ((c['web_presence_notes'] as String? ?? '').isNotEmpty) c['web_presence_notes']].join('\n')),
        phone: Value(phone?.isEmpty == true ? null : phone),
        email: Value(email?.isEmpty == true ? null : email),
        address: Value(c['address'] as String?),
        linksJson: Value(jsonEncode(links)),
        sourcesJson: Value(sources),
        pitch: Value(c['pitch_angle'] as String?),
        needScore: Value(needScore(
          presence: report.presence,
          turnoverInr: turnover,
          hasPhone: phone?.isNotEmpty == true,
          hasEmail: email?.isNotEmpty == true,
          links: links.length,
        )),
        status: const Value('NEW'),
        discoveredAt: Value(now),
        updatedAt: Value(now),
      ));
    }

    if (inserts.isNotEmpty) await db.batch((b) => b.insertAll(db.businessLeads, inserts));
    return BusinessDiscoveryResult(
      found: candidates.length,
      saved: inserts.length,
      skippedBelowCrore: belowCrore,
      skippedGoodWebsite: goodSite,
      duplicates: dupes,
      webSearches: research.webSearches,
    );
  }
}

/// Formats INR in Indian units: ₹4.5 Cr, ₹80 L.
String formatInr(double? v) {
  if (v == null) return '—';
  if (v >= 1e7) {
    final cr = v / 1e7;
    return '₹${cr >= 100 ? cr.round() : cr.toStringAsFixed(cr >= 10 ? 0 : 1)} Cr';
  }
  if (v >= 1e5) return '₹${(v / 1e5).toStringAsFixed(0)} L';
  return '₹${v.round()}';
}
