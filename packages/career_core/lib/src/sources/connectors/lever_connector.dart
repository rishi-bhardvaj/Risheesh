import 'package:http/http.dart' as http;

import '../../util/feed_utils.dart';
import '../source_connector.dart';

class LeverConnector extends SourceConnector {
  final http.Client _client;
  final List<String> organizations;

  LeverConnector({
    http.Client? client,
    List<String>? organizations,
  })  : _client = client ?? http.Client(),
        organizations = organizations ??
            const ['palantir', 'deliveroo', 'atlassian', 'auth0', 'braze'];

  @override
  String get id => 'lever';

  @override
  String get displayName => 'Lever Public Postings';

  @override
  Stream<RawJob> fetch({String? query, String? location, bool remoteOnly = false}) async* {
    for (final org in organizations) {
      final url = Uri.parse('https://api.lever.co/v0/postings/$org?mode=json');
      try {
        final body = await FeedUtils.getBody(_client, url, timeout: const Duration(seconds: 8));
        final data = await FeedUtils.decodeJson(body);
        if (data is! List) continue;

        for (final item in data) {
          if (item is! Map<String, dynamic>) continue;
          final title = item['text']?.toString() ?? '';
          final jobId = item['id']?.toString() ?? '';
          final jobUrl = item['hostedUrl']?.toString() ?? '';
          final categories = item['categories'] as Map? ?? const {};
          final loc = categories['location']?.toString() ?? '';
          final descPlain = item['descriptionPlain']?.toString() ?? '';
          final createdAtMs = (item['createdAt'] as num?)?.toInt();
          final postedAt = createdAtMs != null ? DateTime.fromMillisecondsSinceEpoch(createdAtMs) : null;

          if (title.isEmpty || jobUrl.isEmpty) continue;

          yield RawJob(
            source: 'lever',
            sourceJobId: jobId.isNotEmpty ? jobId : jobUrl,
            url: jobUrl,
            title: title,
            company: FeedUtils.prettifyToken(org),
            location: loc,
            description: descPlain,
            postedAt: postedAt,
            isRemote: loc.toLowerCase().contains('remote') || title.toLowerCase().contains('remote'),
            atsProvider: 'LEVER',
            metadata: {'organization': org},
          );
        }
      } catch (_) {
        continue;
      }
    }
  }
}
