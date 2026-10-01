import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../util/feed_utils.dart';
import '../source_connector.dart';

class GreenhouseConnector extends SourceConnector {
  final http.Client _client;
  final List<String> boardTokens;

  GreenhouseConnector({
    http.Client? client,
    List<String>? boardTokens,
  })  : _client = client ?? http.Client(),
        boardTokens = boardTokens ??
            const [
              'airbnb', 'stripe', 'figma', 'cloudflare', 'databricks', 'gusto',
              'hashicorp', 'discord', 'ramp', 'retool', 'deel', 'rippling',
            ];

  @override
  String get id => 'greenhouse';

  @override
  String get displayName => 'Greenhouse Public Boards';

  @override
  Stream<RawJob> fetch({String? query, String? location, bool remoteOnly = false}) async* {
    for (final board in boardTokens) {
      final url = Uri.parse('https://boards-api.greenhouse.io/v1/boards/$board/jobs?content=true');
      try {
        final body = await FeedUtils.getBody(_client, url, timeout: const Duration(seconds: 8));
        final data = await FeedUtils.decodeJson(body);
        if (data is! Map<String, dynamic>) continue;
        final jobs = data['jobs'] as List? ?? const [];

        for (final item in jobs) {
          if (item is! Map<String, dynamic>) continue;
          final title = item['title']?.toString() ?? '';
          final jobId = item['id']?.toString() ?? '';
          final jobUrl = item['absolute_url']?.toString() ?? '';
          final locName = (item['location'] as Map?)?['name']?.toString() ?? '';
          final content = item['content']?.toString() ?? '';
          final updatedAt = DateTime.tryParse(item['updated_at']?.toString() ?? '');

          if (title.isEmpty || jobUrl.isEmpty) continue;

          yield RawJob(
            source: 'greenhouse',
            sourceJobId: jobId.isNotEmpty ? jobId : jobUrl,
            url: jobUrl,
            title: title,
            company: FeedUtils.prettifyToken(board),
            location: locName,
            description: content,
            postedAt: updatedAt,
            isRemote: locName.toLowerCase().contains('remote') || title.toLowerCase().contains('remote'),
            atsProvider: 'GREENHOUSE',
            metadata: {'board': board},
          );
        }
      } catch (_) {
        // Individual board failure does not halt the stream
        continue;
      }
    }
  }
}
