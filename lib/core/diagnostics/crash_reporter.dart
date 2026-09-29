import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CrashReporter {
  static final CrashReporter instance = CrashReporter._();
  CrashReporter._();

  File? _logFile;

  Future<void> initialize() async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      recordError(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack);
      return true;
    };

    try {
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        _logFile = File('${dir.path}/crash_logs.txt');
      }
    } catch (_) {}
  }

  void recordError(dynamic error, StackTrace? stack) {
    debugPrint('[CrashReporter] Uncaught error: $error\n$stack');
    try {
      if (_logFile != null) {
        final entry = '${DateTime.now().toIso8601String()} ERROR: $error\n$stack\n---\n';
        _logFile!.writeAsStringSync(entry, mode: FileMode.append, flush: true);
      }
    } catch (_) {}
  }
}
