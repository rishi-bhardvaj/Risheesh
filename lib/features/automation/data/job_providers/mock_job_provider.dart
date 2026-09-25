import '../../domain/automation_models.dart';
import 'job_provider.dart';

class MockJobProvider implements JobProvider {
  final bool shouldFail;

  MockJobProvider({this.shouldFail = false});

  @override
  String get providerId => 'mock_provider';

  @override
  String get providerName => 'Simulated Tech Feed';

  @override
  String get feedUrl => 'https://mock.example.com/feed.rss';

  @override
  bool get isRss => true;

  @override
  Future<bool> testConnection() async {
    if (shouldFail) return false;
    return true;
  }

  @override
  Future<List<RawJobItem>> searchJobs({String? query, String? location, bool? remoteOnly}) async {
    if (shouldFail) {
      throw Exception('Simulated provider connection failure');
    }

    return [
      RawJobItem(
        title: 'Senior Flutter Engineer',
        company: 'Stripe',
        location: 'Remote',
        skills: 'Flutter, Dart, Riverpod, Drift',
        url: 'https://stripe.com/jobs/flutter-sr-101',
        description: 'Lead mobile development for our global financial platform.',
        salary: '\$150,000 - \$180,000',
        isRemote: true,
        publishedAt: DateTime.now(),
      ),
      RawJobItem(
        title: 'Backend Systems Architect',
        company: 'GitLab',
        location: 'Remote',
        skills: 'Go, PostgreSQL, Docker, Kubernetes',
        url: 'https://gitlab.com/jobs/arch-202',
        description: 'Design distributed resilient infrastructure.',
        salary: '\$160,000 - \$200,000',
        isRemote: true,
        publishedAt: DateTime.now(),
      ),
    ];
  }
}
