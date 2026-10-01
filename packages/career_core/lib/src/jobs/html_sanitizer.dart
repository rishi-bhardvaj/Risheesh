import '../util/feed_utils.dart';

class HtmlSanitizer {
  HtmlSanitizer._();

  /// Converts HTML to clean, plain text. Drops script, style, iframe,
  /// preserves paragraph & bullet line breaks, and decodes HTML entities.
  /// Capped at 50,000 characters.
  static String sanitize(String? html) {
    if (html == null || html.trim().isEmpty) return '';
    final text = FeedUtils.htmlToText(html);
    return text.length > 50000 ? text.substring(0, 50000).trim() : text;
  }
}
