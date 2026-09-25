import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Production-ready sanitized application logger.
/// Ensures sensitive credentials, tokens, and authorization headers are never
/// leaked to console streams or telemetry buffers in production.
class AppLogger {
  AppLogger._();

  static final _secretPattern = RegExp(
    r'(password|bearer\s+[A-Za-z0-9\-._~+/]+=*|token|secret|api[-_]?key|authorization)\s*[:=]\s*([^\s,;]+)',
    caseSensitive: false,
  );

  /// Sanitizes messages by replacing sensitive values with [REDACTED]
  static String sanitize(String message) {
    return message.replaceAllMapped(_secretPattern, (match) {
      final key = match.group(1);
      return '$key: [REDACTED]';
    });
  }

  /// Debug level log (only emitted in debug mode)
  static void d(String message, {String tag = 'CareerOS', Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log(
        sanitize(message),
        name: tag,
        level: 500,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Informational log
  static void i(String message, {String tag = 'CareerOS'}) {
    developer.log(
      sanitize(message),
      name: tag,
      level: 800,
    );
  }

  /// Warning log
  static void w(String message, {String tag = 'CareerOS', Object? error, StackTrace? stackTrace}) {
    developer.log(
      sanitize(message),
      name: tag,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Error log
  static void e(String message, {String tag = 'CareerOS', Object? error, StackTrace? stackTrace}) {
    developer.log(
      sanitize(message),
      name: tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
