import 'package:http/http.dart' as http;

import '../../util/feed_utils.dart';
import '../source_connector.dart';

class RemoteOkConnector extends SourceConnector {
  final http.Client _client;

  RemoteOkConnector({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get id => 'remoteok';

  @override
  String get displayName => 'RemoteOK';

  @override
  Stream<RawJob> fetch({String? query, String? location, bool remoteOnly = false}) async* {
    final url = Uri.parse('https://remoteok.com/api');
    try {
      final body = await FeedUtils.getBody(_client, url, timeout: const Duration(seconds: 10));
      final data = await FeedUtils.decodeJson(body);
      if (data is! List) return;

      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        // Skip legal disclaimer object
        if (item.containsKey('legal')) continue;

        final position = item['position']?.toString() ?? '';
        final company = item['company']?.toString() ?? '';
        final jobUrl = item['url']?.toString() ?? '';
        final jobId = item['id']?.toString() ?? jobUrl;
        final tags = (item['tags'] as List?)?.map((t) => t.toString()).toList() ?? const [];
        final desc = item['description']?.toString() ?? '';
        final dateStr = item['date']?.toString();
        final postedAt = dateStr != null ? DateTime.tryParse(dateStr) : null;
        final loc = item['location']?.toString() ?? 'Remote';

        if (position.isEmpty || company.isEmpty || jobUrl.isEmpty) continue;

        yield RawJob(
          source: 'remoteok',
          sourceJobId: jobId,
          url: jobUrl,
          title: position,
          company: company,
          location: loc,
          description: desc,
          skills: tags,
          postedAt: postedAt,
          isRemote: true,
          atsProvider: 'REMOTEOK',
          metadata: {'tags': tags},
        );
      }
    } catch (_) {
      return;
    }
  }
}
