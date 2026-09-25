import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/automation_models.dart';
import 'job_provider.dart';

class RssJobProvider implements JobProvider {
  @override
  final String providerId;
  @override
  final String providerName;
  @override
  final String feedUrl;
  final http.Client _client;

  RssJobProvider({
    required this.providerId,
    required this.providerName,
    required this.feedUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  bool get isRss => true;

  @override
  Future<bool> testConnection() async {
    try {
      final response = await _client.get(
        Uri.parse(feedUrl),
        headers: {'User-Agent': 'PersonalCareerOS/1.0 (RSS Reader)'},
      ).timeout(const Duration(seconds: 10));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<RawJobItem>> searchJobs({String? query, String? location, bool? remoteOnly}) async {
    try {
      final response = await _client.get(
        Uri.parse(feedUrl),
        headers: {'User-Agent': 'PersonalCareerOS/1.0 (RSS Reader)'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return [];
      }

      final body = utf8.decode(response.bodyBytes);
      final items = _parseRssXml(body);

      // Filter by query if provided
      if (query == null || query.trim().isEmpty) {
        return items;
      }

      final lowerQuery = query.toLowerCase();
      final keywords = lowerQuery.split(RegExp(r'[,| ]+')).where((k) => k.isNotEmpty).toList();

      return items.where((job) {
        final content = '${job.title} ${job.company} ${job.skills ?? ''} ${job.description ?? ''}'.toLowerCase();
        return keywords.any((kw) => content.contains(kw));
      }).toList();
    } catch (e) {
      return [];
    }
  }

  List<RawJobItem> _parseRssXml(String xmlString) {
    final List<RawJobItem> items = [];
    final itemPattern = RegExp(r'<item>([\s\S]*?)<\/item>', caseSensitive: false);
    final matches = itemPattern.allMatches(xmlString);

    for (final match in matches) {
      final itemBlock = match.group(1) ?? '';
      final title = _extractXmlTag(itemBlock, 'title') ?? 'Untitled Position';
      final link = _extractXmlTag(itemBlock, 'link') ?? _extractXmlTag(itemBlock, 'guid') ?? '';
      final description = _extractXmlTag(itemBlock, 'description') ?? '';
      final pubDateStr = _extractXmlTag(itemBlock, 'pubDate');

      DateTime? publishedAt;
      if (pubDateStr != null) {
        try {
          publishedAt = DateTime.tryParse(pubDateStr);
        } catch (_) {}
      }

      // Try extracting company from title (e.g. "Company: Title" or "Title at Company")
      String parsedCompany = providerName;
      String parsedTitle = title;

      if (title.contains(': ')) {
        final parts = title.split(': ');
        parsedCompany = parts[0].trim();
        parsedTitle = parts.sublist(1).join(': ').trim();
      } else if (title.contains(' at ')) {
        final parts = title.split(' at ');
        parsedTitle = parts[0].trim();
        parsedCompany = parts.sublist(1).join(' at ').trim();
      }

      items.add(RawJobItem(
        title: parsedTitle,
        company: parsedCompany,
        location: 'Remote',
        url: link,
        description: description,
        isRemote: true,
        publishedAt: publishedAt ?? DateTime.now(),
      ));
    }

    return items;
  }

  String? _extractXmlTag(String xml, String tag) {
    final pattern = RegExp('<$tag(?:[^>]*)>(?:<!\\[CDATA\\[([\\s\\S]*?)\\]\\]>|([\\s\\S]*?))<\\/$tag>', caseSensitive: false);
    final match = pattern.firstMatch(xml);
    if (match != null) {
      final val = match.group(1) ?? match.group(2);
      return val?.trim();
    }
    return null;
  }
}
