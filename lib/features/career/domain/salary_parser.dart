/// Annualized salary range parsed from free text such as "$120k – $160k",
/// "$90 - $150 /hour", "₹18 LPA", "12–18 lakhs", "1.2 Cr", "USD 95,000", "€60k".
class SalaryRange {
  final double min;
  final double max;
  final String currency;

  const SalaryRange(this.min, this.max, this.currency);

  double get mid => (min + max) / 2;
}

class SalaryParser {
  static const _hoursPerYear = 2080;

  static SalaryRange? parse(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final t = text.toLowerCase();

    // Currency detection
    String currency = 'USD';
    if (t.contains('₹') || t.contains('inr') || t.contains('lpa') || t.contains('lakh') || t.contains('lac') || t.contains('cr')) {
      currency = 'INR';
    } else if (t.contains('€') || t.contains('eur')) {
      currency = 'EUR';
    } else if (t.contains('£') || t.contains('gbp')) {
      currency = 'GBP';
    } else if (t.contains('cad') || t.contains('c\$')) {
      currency = 'CAD';
    } else if (t.contains('aud') || t.contains('a\$')) {
      currency = 'AUD';
    } else if (t.contains('aed') || t.contains('dirham')) {
      currency = 'AED';
    } else if (t.contains('sgd') || t.contains('s\$')) {
      currency = 'SGD';
    }

    final rawMatches = <({double val, String? unit})>[];
    for (final m in RegExp(r'(\d[\d,]*(?:\.\d+)?)\s*(k|m|cr|crore|crores|lpa|lakh|lakhs|lac|lacs)?\b').allMatches(t)) {
      final v = double.tryParse(m.group(1)!.replaceAll(',', ''));
      if (v == null) continue;
      rawMatches.add((val: v, unit: m.group(2)));
    }
    if (rawMatches.isEmpty) return null;

    // Propagate unit backward if range like "12–18 lakhs"
    String? commonUnit;
    for (final item in rawMatches.reversed) {
      if (item.unit != null) {
        commonUnit = item.unit;
        break;
      }
    }

    final values = <double>[];
    for (final item in rawMatches) {
      var v = item.val;
      final unit = item.unit ?? (v < 1000 ? commonUnit : null);
      switch (unit) {
        case 'k':
          v *= 1000;
        case 'm':
          v *= 1000000;
        case 'cr':
        case 'crore':
        case 'crores':
          v *= 10000000;
        case 'lpa':
        case 'lakh':
        case 'lakhs':
        case 'lac':
        case 'lacs':
          v *= 100000;
      }
      values.add(v);
    }

    var min = values.reduce((a, b) => a < b ? a : b);
    var max = values.reduce((a, b) => a > b ? a : b);
    final hourly = RegExp(r'/\s*h(ou)?r|per hour|hourly').hasMatch(t) || (max < 500 && currency != 'INR');
    final monthly = RegExp(r'/\s*mo|per month|monthly').hasMatch(t);
    if (hourly) {
      min *= _hoursPerYear;
      max *= _hoursPerYear;
    } else if (monthly) {
      min *= 12;
      max *= 12;
    }

    // Reject implausible annual figures
    if (currency == 'INR') {
      if (max < 50000 || max > 200000000) return null;
    } else {
      if (max < 5000 || max > 5000000) return null;
    }

    if (min < max * 0.2) min = max; // noise filter
    return SalaryRange(min, max, currency);
  }

  static String format(double v, {String currency = 'USD'}) {
    final cur = currency.toUpperCase();
    if (cur == 'INR') {
      if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1).replaceAll('.0', '')} Cr';
      if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1).replaceAll('.0', '')} LPA';
      return '₹${v.round()}';
    }
    final symbol = switch (cur) {
      'EUR' => '€',
      'GBP' => '£',
      'CAD' => 'CA\$',
      'AUD' => 'AU\$',
      _ => r'$',
    };
    if (v >= 1000000) return '$symbol${(v / 1000000).toStringAsFixed(1)}M';
    return '$symbol${(v / 1000).round()}k';
  }
}
