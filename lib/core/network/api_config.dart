class ApiConfig {
  static const String defaultProductionUrl = 'https://risheesh-backend.onrender.com';

  /// Production backend URL, optionally overridden at build time:
  /// `flutter build apk --dart-define=API_BASE_URL=https://your-backend.example.com`
  static const String _configured = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configured.isNotEmpty) return _configured;
    return defaultProductionUrl;
  }
}
