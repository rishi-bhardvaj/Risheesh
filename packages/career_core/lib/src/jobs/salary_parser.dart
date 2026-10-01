/// Annualized salary range parsed from free text such as "$120k – $160k",
/// "$90 - $150 /hour", "USD 95,000", "€60k".
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
    final currency = t.contains('€') || t.contains('eur')
        ? 'EUR'
        : t.contains('£') || t.contains('gbp')
            ? 'GBP'
            : t.contains('₹') || t.contains('inr') || t.contains('lpa')
                ? 'INR'
                : 'USD';

    final values = <double>[];
    for (final m in RegExp(r'(\d[\d,]*(?:\.\d+)?)\s*(k|m|lpa|lakh)?\b').allMatches(t)) {
      var v = double.tryParse(m.group(1)!.replaceAll(',', ''));
      if (v == null) continue;
      switch (m.group(2)) {
        case 'k':
          v *= 1000;
        case 'm':
          v *= 1000000;
        case 'lpa':
        case 'lakh':
          v *= 100000;
      }
      values.add(v);
    }
    if (values.isEmpty) return null;

    var min = values.reduce((a, b) => a < b ? a : b);
    var max = values.reduce((a, b) => a > b ? a : b);
    final hourly = RegExp(r'/\s*h(ou)?r|per hour|hourly').hasMatch(t) || max < 500;
    final monthly = RegExp(r'/\s*mo|per month|monthly').hasMatch(t);
    if (hourly) {
      min *= _hoursPerYear;
      max *= _hoursPerYear;
    } else if (monthly) {
      min *= 12;
      max *= 12;
    }
    // Reject implausible annual figures (years, IDs, typos).
    if (max < 5000 || max > 5000000) return null;
    if (min < max * 0.2) min = max; // "$5 - $150k" style noise
    return SalaryRange(min, max, currency);
  }

  static String format(double v, {String currency = 'USD'}) {
    final symbol = switch (currency) { 'EUR' => '€', 'GBP' => '£', 'INR' => '₹', _ => r'$' };
    if (v >= 1000000) return '$symbol${(v / 1000000).toStringAsFixed(1)}M';
    return '$symbol${(v / 1000).round()}k';
  }
}
