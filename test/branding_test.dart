import 'dart:io';
import 'package:career_os/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Branding & Naming Integrity Tests', () {
    test('App name constant is Risheesh', () {
      expect(AppConstants.appName, equals('Risheesh'));
    });

    test('lib/ directory contains no stale "Career OS" UI strings', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];
      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.toLowerCase().contains('career os')) {
            violations.add('${file.path}:${i + 1}: $line');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Found stale "Career OS" references: ${violations.join('\n')}',
      );
    });

    test('Branding assets exist and are non-empty', () {
      expect(File('assets/branding/logo_1024.png').existsSync(), isTrue);
      expect(File('assets/branding/logo_foreground.png').existsSync(), isTrue);
      expect(File('assets/branding/logo_monochrome.png').existsSync(), isTrue);
      expect(File('assets/branding/logo.svg').existsSync(), isTrue);
      expect(File('android/app/src/main/res/drawable/ic_stat_risheesh.xml').existsSync(), isTrue);
    });
  });
}
