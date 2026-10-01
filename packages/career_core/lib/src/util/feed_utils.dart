import 'dart:convert';
import 'dart:isolate';
import 'package:http/http.dart' as http;

/// Shared helpers for the public job / freelance / LeetCode feeds.
/// Pure Dart implementation without Flutter foundation dependencies.
class FeedUtils {
  FeedUtils._();

  static const userAgent =
      'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36';

  static const jsonHeaders = {'User-Agent': userAgent, 'Accept': 'application/json'};
  static const rssHeaders = {'User-Agent': userAgent, 'Accept': 'application/rss+xml, application/xml, text/xml'};

  static Future<String> getBody(
    http.Client client,
    Uri url, {
    Map<String, String> headers = jsonHeaders,
    Duration timeout = const Duration(seconds: 8),
    Duration bodyTimeout = const Duration(seconds: 25),
  }) async {
    final http.StreamedResponse response;
    final List<int> bytes;
    try {
      final request = http.Request('GET', url)..headers.addAll(headers);
      response = await client.send(request).timeout(timeout);
      bytes = await response.stream.toBytes().timeout(bodyTimeout);
    } on Exception catch (e) {
      throw FeedException(_describeTransportError(e, timeout));
    }
    if (response.statusCode == 429) throw const FeedException('Rate limited (HTTP 429)');
    if (response.statusCode == 404) throw const FeedException('Board not found (HTTP 404)');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FeedException('HTTP ${response.statusCode}');
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  static Future<dynamic> decodeJson(String body) async {
    if (body.length < 64 * 1024) return jsonDecode(body);
    return Isolate.run(() => jsonDecode(body));
  }

  static String _describeTransportError(Object e, Duration timeout) {
    final text = e.toString();
    if (text.contains('TimeoutException')) return 'Timed out after ${timeout.inSeconds}s';
    if (text.contains('SocketException') || text.contains('Failed host lookup')) return 'No network connection';
    if (text.contains('HandshakeException')) return 'TLS handshake failed';
    return text.length > 120 ? '${text.substring(0, 120)}…' : text;
  }

  static final _namedEntities = <String, String>{
    'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'", 'nbsp': ' ',
    'ndash': '–', 'mdash': '—', 'hellip': '…', 'rsquo': '’', 'lsquo': '‘',
    'rdquo': '”', 'ldquo': '“', 'bull': '•', 'middot': '·', 'copy': '©',
    'reg': '®', 'trade': '™', 'euro': '€', 'pound': '£', 'rarr': '→',
  };
  static final _entityPattern = RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);');

  static String decodeEntities(String input) {
    return repairMojibake(input).replaceAllMapped(_entityPattern, (m) {
      final code = m.group(1)!;
      if (code.startsWith('#x') || code.startsWith('#X')) {
        final v = int.tryParse(code.substring(2), radix: 16);
        return v == null ? m.group(0)! : String.fromCharCode(v);
      }
      if (code.startsWith('#')) {
        final v = int.tryParse(code.substring(1));
        return v == null ? m.group(0)! : String.fromCharCode(v);
      }
      return _namedEntities[code.toLowerCase()] ?? m.group(0)!;
    });
  }

  static String htmlToText(String? html) {
    if (html == null || html.isEmpty) return '';
    var s = html;
    if (s.contains('&lt;')) s = decodeEntities(s);
    s = s
        .replaceAll(RegExp(r'<\s*(script|style)[^>]*>.*?<\s*/\s*\1\s*>', caseSensitive: false, dotAll: true), ' ')
        .replaceAll(RegExp(r'<\s*li[^>]*>', caseSensitive: false), '\n• ')
        .replaceAll(RegExp(r'<\s*(br|/p|/div|/h[1-6]|/li|/ul|/ol)[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ');
    s = decodeEntities(s);
    return repairMojibake(s)
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'[ \t ]+'), ' ').trim())
        .where((l) => l.isNotEmpty && l != '•')
        .join('\n')
        .trim();
  }

  static const _cp1252 = <int, int>{
    0x20AC: 0x80, 0x201A: 0x82, 0x0192: 0x83, 0x201E: 0x84, 0x2026: 0x85, 0x2020: 0x86,
    0x2021: 0x87, 0x02C6: 0x88, 0x2030: 0x89, 0x0160: 0x8A, 0x2039: 0x8B, 0x0152: 0x8C,
    0x017D: 0x8E, 0x2018: 0x91, 0x2019: 0x92, 0x201C: 0x93, 0x201D: 0x94, 0x2022: 0x95,
    0x2013: 0x96, 0x2014: 0x97, 0x02DC: 0x98, 0x2122: 0x99, 0x0161: 0x9A, 0x203A: 0x9B,
    0x0153: 0x9C, 0x017E: 0x9E, 0x0178: 0x9F,
  };
  static final _mojibake = RegExp('[\u00C2\u00C3][\u0080-\u00BF]|\u00E2\u20AC');

  static String repairMojibake(String s) {
    if (!_mojibake.hasMatch(s)) return s;
    final bytes = <int>[];
    for (final r in s.runes) {
      final b = r < 0x100 ? r : _cp1252[r];
      if (b == null) return s;
      bytes.add(b);
    }
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return s;
    }
  }

  static String truncate(String s, int max) => s.length <= max ? s : '${s.substring(0, max - 1).trimRight()}…';

  static const _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  static DateTime? parseFeedDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final iso = DateTime.tryParse(raw.trim());
    if (iso != null) return iso;
    final m = RegExp(
      r'(\d{1,2})\s+([A-Za-z]{3})[a-z]*\s+(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|[A-Z]{1,4})?',
    ).firstMatch(raw);
    if (m == null) return null;
    final month = _months[m.group(2)!.toLowerCase()];
    if (month == null) return null;
    var dt = DateTime.utc(
      int.parse(m.group(3)!),
      month,
      int.parse(m.group(1)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.tryParse(m.group(6) ?? '0') ?? 0,
    );
    final zone = m.group(7);
    if (zone != null && (zone.startsWith('+') || zone.startsWith('-'))) {
      final sign = zone.startsWith('-') ? -1 : 1;
      final offset = Duration(hours: int.parse(zone.substring(1, 3)), minutes: int.parse(zone.substring(3, 5)));
      dt = sign > 0 ? dt.subtract(offset) : dt.add(offset);
    }
    return dt.toLocal();
  }

  static List<Map<String, String>> parseRssItems(String xml) {
    final items = <Map<String, String>>[];
    for (final m in RegExp(r'<item\b[^>]*>(.*?)</item>', dotAll: true).allMatches(xml)) {
      final block = m.group(1)!;
      final fields = <String, String>{};
      for (final t in RegExp(r'<([a-zA-Z:_]+)\b[^>]*>(.*?)</\1>', dotAll: true).allMatches(block)) {
        var value = t.group(2)!.trim();
        final cdata = RegExp(r'^<!\[CDATA\[(.*)\]\]>$', dotAll: true).firstMatch(value);
        if (cdata != null) value = cdata.group(1)!.trim();
        fields.putIfAbsent(t.group(1)!, () => value);
      }
      items.add(fields);
    }
    return items;
  }

  static String prettifyToken(String token) =>
      token.isEmpty ? token : token[0].toUpperCase() + token.substring(1);
}

class FeedException implements Exception {
  final String message;
  const FeedException(this.message);

  @override
  String toString() => message;
}

class SourceStatus {
  final String sourceId;
  final String label;
  final int itemCount;
  final String? error;
  final Duration elapsed;

  const SourceStatus({
    required this.sourceId,
    required this.label,
    required this.itemCount,
    this.error,
    this.elapsed = Duration.zero,
  });

  bool get ok => error == null;
}
