import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  static Future<bool> launchURL(dynamic first, [dynamic second]) async {
    BuildContext? context;
    String? urlString;

    if (first is BuildContext) {
      context = first;
      urlString = second is String ? second : null;
    } else if (first is String?) {
      urlString = first;
      if (second is BuildContext) {
        context = second;
      }
    }

    if (urlString == null || urlString.trim().isEmpty) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No URL provided')),
        );
      }
      return false;
    }

    String formatted = urlString.trim();
    // Keep explicit schemes (tel:, mailto:, https:); bare hosts get https.
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(formatted)) {
      formatted = 'https://$formatted';
    }

    final uri = Uri.tryParse(formatted);
    if (uri == null) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid URL format')),
        );
      }
      return false;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $urlString')),
        );
      }
      return launched;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $e')),
        );
      }
      return false;
    }
  }
}
