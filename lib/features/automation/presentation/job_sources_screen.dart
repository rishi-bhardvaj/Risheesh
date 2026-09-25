import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/job_providers/rss_job_provider.dart';

class JobSourcesScreen extends ConsumerStatefulWidget {
  const JobSourcesScreen({super.key});

  @override
  ConsumerState<JobSourcesScreen> createState() => _JobSourcesScreenState();
}

class _JobSourcesScreenState extends ConsumerState<JobSourcesScreen> {
  final Map<String, bool?> _testingStatus = {};

  final List<Map<String, String>> _defaultSources = [
    {
      'id': 'remote_ok',
      'name': 'RemoteOK RSS Feed',
      'url': 'https://remoteok.com/remote-jobs.rss',
      'description': 'Public RSS feed of verified remote technology and software engineering jobs.',
    },
    {
      'id': 'we_work_remotely',
      'name': 'WeWorkRemotely RSS Feed',
      'url': 'https://weworkremotely.com/remote-jobs.rss',
      'description': 'Official public RSS stream for programming and software design roles.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Sources & Feeds'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer.withOpacity(0.4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.rss_feed, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Legitimate Public Feeds',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Career OS consumes standard, publicly provided RSS streams. No web scraping, CAPTCHA bypass, or auth circumvention.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'CONFIGURED SOURCES',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          ..._defaultSources.map((source) => _buildSourceCard(source, theme)),
        ],
      ),
    );
  }

  Widget _buildSourceCard(Map<String, String> source, ThemeData theme) {
    final id = source['id']!;
    final name = source['name']!;
    final url = source['url']!;
    final desc = source['description']!;
    final isSuccess = _testingStatus[id];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.feed_outlined, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('PUBLIC RSS', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 6),
            Text('Endpoint: $url', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontFamily: 'monospace')),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isSuccess != null)
                  Row(
                    children: [
                      Icon(isSuccess ? Icons.check_circle : Icons.error_outline,
                          color: isSuccess ? Colors.green : Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        isSuccess ? 'Endpoint reachable' : 'Connection failed',
                        style: TextStyle(
                          color: isSuccess ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.wifi_find, size: 16),
                  label: const Text('Test Feed'),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => _testFeed(id, name, url),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testFeed(String id, String name, String url) async {
    final provider = RssJobProvider(providerId: id, providerName: name, feedUrl: url);
    final ok = await provider.testConnection();
    setState(() {
      _testingStatus[id] = ok;
    });
  }
}
