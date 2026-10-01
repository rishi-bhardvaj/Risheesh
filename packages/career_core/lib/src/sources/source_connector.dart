import 'platform_policy.dart';

class RawJob {
  final String source;
  final String sourceJobId;
  final String url;
  final String title;
  final String company;
  final String? location;
  final String? salary;
  final String? description;
  final List<String> skills;
  final DateTime? postedAt;
  final String? employmentType;
  final bool isRemote;
  final String? atsProvider;
  final Map<String, dynamic> metadata;

  const RawJob({
    required this.source,
    required this.sourceJobId,
    required this.url,
    required this.title,
    required this.company,
    this.location,
    this.salary,
    this.description,
    this.skills = const [],
    this.postedAt,
    this.employmentType,
    this.isRemote = false,
    this.atsProvider,
    this.metadata = const {},
  });
}

class RateLimitConfig {
  final int maxRequestsPerMinute;
  final Duration minInterval;

  const RateLimitConfig({
    this.maxRequestsPerMinute = 30,
    this.minInterval = const Duration(milliseconds: 500),
  });
}

abstract class SourceConnector {
  String get id;
  String get displayName;
  PlatformPolicyRule? get policy => PlatformPolicy.rules[id];
  RateLimitConfig get rateLimit => const RateLimitConfig();

  Stream<RawJob> fetch({String? query, String? location, bool remoteOnly = false});
}
