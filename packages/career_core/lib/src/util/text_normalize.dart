import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Text normalization and similarity utilities.
class TextNormalize {
  TextNormalize._();

  static String collapseWhitespace(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String cleanToken(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9+#.]'), '').trim();

  static String sha1Hex(String s) => sha1.convert(utf8.encode(s)).toString();

  static String sha256Hex(String s) => sha256.convert(utf8.encode(s)).toString();

  /// Normalized company name: collapses spaces, strips legal suffixes like
  /// Pvt Ltd, Private Limited, Inc, LLC, Technologies, Labs, Corp, Corporation, Ltd.
  static String normalizeCompany(String company) {
    var c = company.toLowerCase().trim();
    c = c.replaceAll(RegExp(r'[,.]'), ' ');
    final suffixes = [
      'private limited',
      'pvt ltd',
      'pvt. ltd.',
      'pvt ltd.',
      'limited',
      'ltd',
      'technologies',
      'technology',
      'solutions',
      'services',
      'enterprises',
      'corporation',
      'corp',
      'incorporated',
      'inc',
      'llc',
      'gmbh',
      'holdings',
      'labs',
      'lab',
      'software',
    ];
    for (final suffix in suffixes) {
      final pattern = RegExp(r'\b' + RegExp.escape(suffix) + r'\b', caseSensitive: false);
      c = c.replaceAll(pattern, '');
    }
    return collapseWhitespace(c);
  }

  /// Normalized title: lowercases, removes seniority prefixes and noise, collapses spaces.
  static String normalizeTitle(String title) {
    var t = title.toLowerCase().trim();
    t = t.replaceAll(RegExp(r'[\(\[\{].*?[\)\]\}]'), ' '); // strip parentheticals e.g. (f/m/d), (remote)
    t = t.replaceAll(RegExp(r'req\s*#?\s*\d+', caseSensitive: false), ' '); // req numbers
    t = t.replaceAll(RegExp(r'\b(sr|jr|senior|junior|lead|staff|principal|associate|intern|level\s*\d+|[iIvVxX]+)\b', caseSensitive: false), ' ');
    return collapseWhitespace(t);
  }

  /// Trigram similarity between two strings (0.0 to 1.0).
  static double trigramSimilarity(String a, String b) {
    final s1 = a.trim().toLowerCase();
    final s2 = b.trim().toLowerCase();
    if (s1 == s2) return 1.0;
    if (s1.length < 3 || s2.length < 3) {
      return s1.contains(s2) || s2.contains(s1) ? 0.7 : 0.0;
    }
    final tri1 = <String, int>{};
    for (var i = 0; i <= s1.length - 3; i++) {
      final sub = s1.substring(i, i + 3);
      tri1[sub] = (tri1[sub] ?? 0) + 1;
    }
    final tri2 = <String, int>{};
    for (var i = 0; i <= s2.length - 3; i++) {
      final sub = s2.substring(i, i + 3);
      tri2[sub] = (tri2[sub] ?? 0) + 1;
    }
    var intersection = 0;
    for (final entry in tri1.entries) {
      if (tri2.containsKey(entry.key)) {
        intersection += entry.value < tri2[entry.key]! ? entry.value : tri2[entry.key]!;
      }
    }
    final total = (s1.length - 2) + (s2.length - 2);
    return total == 0 ? 0.0 : (2.0 * intersection) / total;
  }
}
