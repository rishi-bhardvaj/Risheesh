import 'dart:convert';
import 'source_connector.dart';

class JsonLdJobPostingParser {
  JsonLdJobPostingParser._();

  static List<RawJob> parse(String jsonLdText, {required String pageUrl}) {
    final results = <RawJob>[];
    try {
      final decoded = jsonDecode(jsonLdText);
      final list = decoded is List ? decoded : [decoded];

      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final type = item['@type']?.toString();
        if (type != 'JobPosting') {
          // May be inside @graph
          final graph = item['@graph'] as List?;
          if (graph != null) {
            for (final g in graph) {
              if (g is Map<String, dynamic> && g['@type']?.toString() == 'JobPosting') {
                final job = _buildJob(g, pageUrl);
                if (job != null) results.add(job);
              }
            }
          }
          continue;
        }

        final job = _buildJob(item, pageUrl);
        if (job != null) results.add(job);
      }
    } catch (_) {
      // Ignored if invalid json
    }
    return results;
  }

  static RawJob? _buildJob(Map<String, dynamic> map, String fallbackUrl) {
    final title = map['title']?.toString() ?? '';
    final org = map['hiringOrganization'];
    final company = org is Map ? org['name']?.toString() ?? '' : (org?.toString() ?? '');
    final url = map['url']?.toString() ?? fallbackUrl;
    final desc = map['description']?.toString() ?? '';
    final dateStr = map['datePosted']?.toString();
    final postedAt = dateStr != null ? DateTime.tryParse(dateStr) : null;
    final empType = map['employmentType']?.toString();

    var location = '';
    final jobLoc = map['jobLocation'];
    if (jobLoc is Map) {
      final addr = jobLoc['address'];
      if (addr is Map) {
        location = [addr['addressLocality'], addr['addressRegion'], addr['addressCountry']].whereType<String>().join(', ');
      }
    }

    final isRemote = location.toLowerCase().contains('remote') ||
        (map['jobLocationType']?.toString().toLowerCase() == 'telecommute');

    if (title.isEmpty || company.isEmpty) return null;

    return RawJob(
      source: 'jsonld',
      sourceJobId: url,
      url: url,
      title: title,
      company: company,
      location: location.isNotEmpty ? location : (isRemote ? 'Remote' : null),
      description: desc,
      postedAt: postedAt,
      employmentType: empType,
      isRemote: isRemote,
      atsProvider: 'JSON_LD',
    );
  }
}
