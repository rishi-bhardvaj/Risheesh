import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _defaultLocalhost = 'http://localhost:8080';
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8080';

  static String get baseUrl {
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
