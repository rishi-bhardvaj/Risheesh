import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _defaultLocalhost = 'http://localhost:8080';
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8080';

  /// Production backend URL, injected at build time:
  /// `flutter build apk --dart-define=API_BASE_URL=https://your-backend.example.com`
  static const String _configured = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configured.isNotEmpty) return _configured;
    if (kIsWeb) {
      return _defaultLocalhost;
    }
    try {
      if (Platform.isAndroid) {
        // If running in Android emulator, 10.0.2.2 maps to host machine localhost
        return _androidEmulatorUrl;
      }
    } catch (_) {}
    return _defaultLocalhost;
  }
}
