import 'package:http/http.dart' as http;

import '../../util/feed_utils.dart';
import '../source_connector.dart';

class WwrRssConnector extends SourceConnector {
  final http.Client _client;

  WwrRssConnector({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get id => 'wwr';

  @override
  String get displayName => 'We Work Remotely RSS';

  @override
  Stream<RawJob> fetch({String? query, String? location, bool remoteOnly = false}) async* {
    final url = Uri.parse('https://weworkremotely.com/categories/remote-programming-jobs.rss');
    try {
      final xml = await FeedUtils.getBody(
        _client,
        url,
        headers: FeedUtils.rssHeaders,
        timeout: const Duration(seconds: 10),
      );
      final items = FeedUtils.parseRssItems(xml);

      for (final item in items) {
        final titleWithCompany = item['title'] ?? '';
        final link = item['link'] ?? '';
        final desc = item['description'] ?? '';
        final pubDate = FeedUtils.parseFeedDate(item['pubDate']);
        final guid = item['guid'] ?? link;

        if (titleWithCompany.isEmpty || link.isEmpty) continue;

        var title = titleWithCompany;
        var company = 'WeWorkRemotely';
        if (titleWithCompany.contains(':')) {
          final parts = titleWithCompany.split(':');
          company = parts[0].trim();
          title = parts.sublist(1).join(':').trim();
        }

        yield RawJob(
          source: 'wwr',
          sourceJobId: guid,
          url: link,
          title: title,
          company: company,
          location: 'Remote',
          description: desc,
          postedAt: pubDate,
          isRemote: true,
          atsProvider: 'WWR',
        );
      }
    } catch (_) {
      return;
    }
  }
}
