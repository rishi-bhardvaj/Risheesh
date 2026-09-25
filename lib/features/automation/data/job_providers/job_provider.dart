import '../../domain/automation_models.dart';

abstract class JobProvider {
  String get providerId;
  String get providerName;
  String get feedUrl;
  bool get isRss;
  
  /// Performs an automated or manual search against the provider
  Future<List<RawJobItem>> searchJobs({String? query, String? location, bool? remoteOnly});

  /// Tests connectivity to the public endpoint
  Future<bool> testConnection();
}
