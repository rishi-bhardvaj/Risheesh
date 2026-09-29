import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../database/app_database.dart';

final fxServiceProvider = Provider<FxService>((ref) {
  final db = ref.watch(databaseProvider);
  return FxService(db);
});

class FxService {
  final AppDatabase db;
  static const Map<String, double> kBundledRatesFromInr = {
    'INR': 1.0,
    'USD': 0.012,
    'EUR': 0.011,
    'GBP': 0.0095,
    'AED': 0.044,
    'SGD': 0.016,
    'CAD': 0.016,
    'AUD': 0.018,
    'JPY': 1.80,
    'CHF': 0.011,
  };

  Map<String, double> _ratesFromInr = Map.from(kBundledRatesFromInr);
  DateTime? _lastFetchedAt;

  FxService(this.db);

  Map<String, double> get currentRates => Map.unmodifiable(_ratesFromInr);
  DateTime? get lastFetchedAt => _lastFetchedAt;

  /// Loads rates from DB cache or fetches fresh rates from remote API.
  Future<void> initialize() async {
    final cached = await db.getLatestFxRate('INR');
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached.ratesJson) as Map<String, dynamic>;
        final map = <String, double>{'INR': 1.0};
        for (final entry in decoded.entries) {
          map[entry.key.toUpperCase()] = (entry.value as num).toDouble();
        }
        _ratesFromInr = map;
        _lastFetchedAt = cached.fetchedAt;

        // If cached rates are under 24 hours old, don't re-fetch immediately
        if (DateTime.now().difference(cached.fetchedAt).inHours < 24) {
          return;
        }
      } catch (e) {
        debugPrint('[FxService] Error decoding cached rates: $e');
      }
    }

    // Refresh rates in background
    await refreshRates();
  }

  /// Attempts to fetch fresh rates from Frankfurter ECB API, then ER-API, then bundled fallback.
  Future<bool> refreshRates() async {
    // 1. Primary: Frankfurter (European Central Bank)
    try {
      final res = await http.get(Uri.parse('https://api.frankfurter.app/latest?from=INR')).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['rates'] is Map) {
          final rates = (data['rates'] as Map).cast<String, dynamic>();
          final map = <String, double>{'INR': 1.0};
          for (final entry in rates.entries) {
            map[entry.key.toUpperCase()] = (entry.value as num).toDouble();
          }
          _ratesFromInr = map;
          _lastFetchedAt = DateTime.now();
          await db.saveFxRate('INR', jsonEncode(map));
          return true;
        }
      }
    } catch (e) {
      debugPrint('[FxService] Frankfurter API failed: $e, trying fallback...');
    }

    // 2. Fallback: Open Exchange Rates API
    try {
      final res = await http.get(Uri.parse('https://open.er-api.com/v6/latest/INR')).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['rates'] is Map) {
          final rates = (data['rates'] as Map).cast<String, dynamic>();
          final map = <String, double>{'INR': 1.0};
          for (final entry in rates.entries) {
            map[entry.key.toUpperCase()] = (entry.value as num).toDouble();
          }
          _ratesFromInr = map;
          _lastFetchedAt = DateTime.now();
          await db.saveFxRate('INR', jsonEncode(map));
          return true;
        }
      }
    } catch (e) {
      debugPrint('[FxService] Open ER-API failed: $e. Using bundled snapshot.');
    }

    return false;
  }

  /// Converts [amount] from currency [from] to currency [to].
  double convert(double amount, String from, String to) {
    final fromUpper = from.toUpperCase();
    final toUpper = to.toUpperCase();

    if (fromUpper == toUpper) return amount;

    final rateFrom = _ratesFromInr[fromUpper] ?? kBundledRatesFromInr[fromUpper] ?? 1.0;
    final rateTo = _ratesFromInr[toUpper] ?? kBundledRatesFromInr[toUpper] ?? 1.0;

    // Convert to INR first: amount in INR = amount / rateFrom
    final amountInInr = amount / rateFrom;

    // Convert from INR to target: target = amountInInr * rateTo
    return amountInInr * rateTo;
  }

  /// Converts any currency amount directly to INR.
  double toInr(double amount, String fromCurrency) => convert(amount, fromCurrency, 'INR');

  /// Converts an INR amount to target currency.
  double fromInr(double inrAmount, String targetCurrency) => convert(inrAmount, 'INR', targetCurrency);

  /// Human-friendly display formatter for salary figures.
  static String formatSalary(double amount, String currency, {bool perYear = true}) {
    final cur = currency.toUpperCase();
    final period = perYear ? '/yr' : '/mo';

    if (cur == 'INR') {
      if (amount >= 10000000) {
        final cr = (amount / 10000000).toStringAsFixed(1).replaceAll('.0', '');
        return '₹$cr Cr $period';
      } else if (amount >= 100000) {
        final l = (amount / 100000).toStringAsFixed(1).replaceAll('.0', '');
        return '₹$l LPA';
      } else {
        return '₹${amount.toStringAsFixed(0)} $period';
      }
    } else if (cur == 'USD') {
      if (amount >= 1000) {
        return '\$${(amount / 1000).toStringAsFixed(0)}k $period';
      }
      return '\$${amount.toStringAsFixed(0)} $period';
    } else if (cur == 'EUR') {
      if (amount >= 1000) {
        return '€${(amount / 1000).toStringAsFixed(0)}k $period';
      }
      return '€${amount.toStringAsFixed(0)} $period';
    } else if (cur == 'GBP') {
      if (amount >= 1000) {
        return '£${(amount / 1000).toStringAsFixed(0)}k $period';
      }
      return '£${amount.toStringAsFixed(0)} $period';
    }

    return '$cur ${amount.toStringAsFixed(0)} $period';
  }
}
