import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/feed_utils.dart';

enum WebPresence {
  noWebsite('NO_WEBSITE', 'No website'),
  shopify('SHOPIFY', 'Shopify store'),
  needsWebsite('NEEDS_WEBSITE', 'Needs a real site'),
  hasWebsite('HAS_WEBSITE', 'Has a good site');

  final String value;
  final String label;
  const WebPresence(this.value, this.label);

  static WebPresence from(String? v) => values.firstWhere((p) => p.value == v, orElse: () => noWebsite);
}

class PresenceReport {
  final WebPresence presence;
  final List<String> notes;
  final String? finalUrl;

  const PresenceReport(this.presence, this.notes, [this.finalUrl]);
}

/// Checks a business's web presence directly instead of trusting what a
/// model claimed. Signals follow LeadScraper's shopify_detector: headers,
/// CDN assets, JS globals and myshopify references.
class WebsiteInspector {
  final http.Client _client;

  WebsiteInspector({http.Client? client}) : _client = client ?? http.Client();

  /// Hosts that are a listing or profile, not the business's own site.
  static const _profileHosts = {
    'instagram.com': 'Instagram', 'facebook.com': 'Facebook', 'fb.com': 'Facebook', 'linktr.ee': 'Linktree',
    'wa.me': 'WhatsApp', 'whatsapp.com': 'WhatsApp', 'indiamart.com': 'IndiaMART', 'justdial.com': 'Justdial',
    'tradeindia.com': 'TradeIndia', 'exportersindia.com': 'ExportersIndia', 'amazon.': 'Amazon', 'flipkart.com': 'Flipkart',
    'meesho.com': 'Meesho', 'zomato.com': 'Zomato', 'swiggy.com': 'Swiggy', 'google.com': 'Google listing',
    'maps.app.goo.gl': 'Google Maps', 'g.page': 'Google Business', 'linkedin.com': 'LinkedIn', 'youtube.com': 'YouTube',
    'x.com': 'X', 'twitter.com': 'X', 'etsy.com': 'Etsy', 'alibaba.com': 'Alibaba', 'yelp.com': 'Yelp',
  };

  static const _freeBuilders = [
    'wixsite.com', 'weebly.com', 'blogspot.', 'wordpress.com', 'godaddysites.com', 'business.site',
    'sites.google.com', 'webnode.', 'jimdosite.com', 'site123.me', 'mystrikingly.com', 'carrd.co',
  ];

  static String? profilePlatform(String url) {
    final host = Uri.tryParse(url.contains('://') ? url : 'https://$url')?.host.toLowerCase() ?? '';
    for (final e in _profileHosts.entries) {
      if (host == e.key || host.endsWith('.${e.key}') || (e.key.endsWith('.') && host.contains(e.key))) return e.value;
    }
    return null;
  }

  Future<PresenceReport> inspect(String? rawUrl) async {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return const PresenceReport(WebPresence.noWebsite, ['No website found']);
    }
    var url = rawUrl.trim();
    if (!url.startsWith('http')) url = 'https://$url';

    final platform = profilePlatform(url);
    if (platform != null) {
      return PresenceReport(WebPresence.noWebsite, ['Only a $platform page, no own website']);
    }

    _Fetched res;
    try {
      res = await _fetch(url);
    } catch (_) {
      // Many small-business sites don't have TLS set up; try plain HTTP.
      try {
        res = await _fetch(url.replaceFirst('https://', 'http://'));
      } catch (e) {
        return PresenceReport(WebPresence.needsWebsite, ['Site unreachable (${_short(e)})'], url);
      }
    }

    final finalUrl = res.url;
    if (res.statusCode >= 400) {
      return PresenceReport(WebPresence.needsWebsite, ['Site returns HTTP ${res.statusCode}'], finalUrl);
    }
    final redirectedTo = profilePlatform(finalUrl);
    if (redirectedTo != null) {
      return PresenceReport(WebPresence.noWebsite, ['Domain just redirects to $redirectedTo'], finalUrl);
    }

    final html = utf8.decode(res.body, allowMalformed: true);
    final lower = html.toLowerCase();
    final headers = res.headers.map((k, v) => MapEntry(k.toLowerCase(), v.toLowerCase()));

    // Shopify
    final shopifySignals = <String>[
      if (headers.keys.any((h) => h == 'x-shopid' || h == 'x-shopify-stage' || h == 'x-sorting-hat-podid')) 'Shopify response headers',
      if ((headers['powered-by'] ?? '').contains('shopify')) 'Powered-By: Shopify',
      if (lower.contains('cdn.shopify.com') || lower.contains('cdn.shopifycdn.net')) 'Assets on cdn.shopify.com',
      if (lower.contains('shopify.theme') || lower.contains('window.shopify')) 'Shopify theme globals',
      if (RegExp(r'[a-z0-9-]+\.myshopify\.com').hasMatch(lower)) 'myshopify.com store',
    ];
    if (shopifySignals.isNotEmpty) {
      final plus = lower.contains('shopify_plus') || lower.contains('checkout.liquid');
      return PresenceReport(
        WebPresence.shopify,
        [plus ? 'Shopify Plus store' : 'Shopify store', ...shopifySignals.take(2)],
        finalUrl,
      );
    }

    // Weak-site signals
    final weak = <String>[];
    final text = FeedUtils.htmlToText(html);
    if (RegExp(r'domain (is )?for sale|buy this domain|parked|under construction|coming soon|website is expired|account suspended')
        .hasMatch(lower)) {
      return PresenceReport(WebPresence.needsWebsite, ['Parked, expired or "coming soon" page'], finalUrl);
    }
    if (finalUrl.startsWith('http://')) weak.add('No HTTPS');
    if (!lower.contains('name="viewport"') && !lower.contains("name='viewport'")) weak.add('Not mobile-friendly (no viewport)');
    final builder = _freeBuilders.where(Uri.parse(finalUrl).host.contains).firstOrNull;
    if (builder != null) weak.add('Free builder subdomain ($builder)');
    if (text.length < 400) weak.add('Almost no content (${text.length} chars)');
    final years = RegExp(r'(?:©|&copy;|copyright)\s*(?:\d{4}\s*[-–]\s*)?((?:19|20)\d{2})')
        .allMatches(lower)
        .map((m) => int.parse(m.group(1)!))
        .toList();
    if (years.isNotEmpty && years.reduce((a, b) => a > b ? a : b) <= DateTime.now().year - 3) {
      weak.add('Last updated around ${years.reduce((a, b) => a > b ? a : b)}');
    }
    if (!RegExp(r'<title>\s*\S').hasMatch(lower)) weak.add('No page title');
    final platformNote = lower.contains('wix.com')
        ? 'Built on Wix'
        : lower.contains('wp-content')
            ? 'Built on WordPress'
            : lower.contains('squarespace')
                ? 'Built on Squarespace'
                : null;

    if (weak.length >= 2 || builder != null) {
      return PresenceReport(WebPresence.needsWebsite, [...weak, ?platformNote], finalUrl);
    }
    return PresenceReport(WebPresence.hasWebsite, ['Modern site', ...weak, ?platformNote], finalUrl);
  }

  Future<_Fetched> _fetch(String url) async {
    final request = http.Request('GET', Uri.parse(url))..headers['User-Agent'] = FeedUtils.userAgent;
    final streamed = await _client.send(request).timeout(const Duration(seconds: 10));
    final body = await streamed.stream.toBytes().timeout(const Duration(seconds: 15));
    // StreamedResponse reports the post-redirect URL on IO clients.
    final finalUrl = streamed is http.BaseResponseWithUrl ? (streamed as http.BaseResponseWithUrl).url.toString() : url;
    return _Fetched(streamed.statusCode, streamed.headers, body, finalUrl);
  }

  static String _short(Object e) {
    final s = e.toString();
    if (s.contains('Timeout')) return 'timed out';
    if (s.contains('Failed host lookup') || s.contains('SocketException')) return 'domain does not resolve';
    if (s.contains('Handshake')) return 'broken SSL';
    return s.length > 60 ? '${s.substring(0, 60)}…' : s;
  }
}

class _Fetched {
  final int statusCode;
  final Map<String, String> headers;
  final List<int> body;
  final String url;
  const _Fetched(this.statusCode, this.headers, this.body, this.url);
}
