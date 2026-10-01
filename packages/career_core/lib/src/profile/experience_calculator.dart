class DateInterval {
  final DateTime start;
  final DateTime end;
  final bool isInternship;

  const DateInterval({
    required this.start,
    required this.end,
    this.isInternship = false,
  });
}

class ExperienceCalculator {
  ExperienceCalculator._();

  static const _monthsMap = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// Parses date ranges such as "Jan 2022 – Present", "2021 - 2023", "06/2020 - 12/2021".
  static (DateTime?, DateTime?) parseRange(String text, {DateTime? now}) {
    final effectiveNow = now ?? DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)); // Asia/Kolkata
    final lower = text.toLowerCase().replaceAll('–', '-').replaceAll('—', '-');

    final parts = lower.split(RegExp(r'\s*-\s*|\s+to\s+'));
    if (parts.isEmpty) return (null, null);

    final start = _parseDate(parts[0]);
    DateTime? end;
    if (parts.length > 1) {
      if (parts[1].contains('present') || parts[1].contains('current') || parts[1].contains('now')) {
        end = effectiveNow;
      } else {
        end = _parseDate(parts[1]);
      }
    } else {
      end = start != null ? DateTime(start.year + 1, start.month) : null;
    }

    return (start, end);
  }

  static DateTime? _parseDate(String raw) {
    final s = raw.trim();
    // 1. "Jan 2022" or "January 2022"
    final m1 = RegExp(r'([a-zA-Z]{3,9})\.?\s+(\d{4})').firstMatch(s);
    if (m1 != null) {
      final monthStr = m1.group(1)!.toLowerCase().substring(0, 3);
      final month = _monthsMap[monthStr] ?? 1;
      final year = int.parse(m1.group(2)!);
      return DateTime.utc(year, month);
    }

    // 2. "06/2020" or "6/2020"
    final m2 = RegExp(r'(\d{1,2})[/-](\d{4})').firstMatch(s);
    if (m2 != null) {
      final month = int.parse(m2.group(1)!);
      final year = int.parse(m2.group(2)!);
      return DateTime.utc(year, month);
    }

    // 3. Just Year "2021"
    final m3 = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(s);
    if (m3 != null) {
      final year = int.parse(m3.group(1)!);
      return DateTime.utc(year, 1);
    }

    return null;
  }

  /// Calculates total experience months as the non-overlapping union of intervals.
  /// Internships are weighted by [internshipWeight] (default 0.5).
  static int calculateTotalMonths(List<DateInterval> intervals, {double internshipWeight = 0.5}) {
    if (intervals.isEmpty) return 0;

    // Filter valid intervals
    final valid = intervals.where((i) => i.end.isAfter(i.start) || i.end.isAtSameMomentAs(i.start)).toList();
    if (valid.isEmpty) return 0;

    // Sort by start date
    valid.sort((a, b) => a.start.compareTo(b.start));

    var totalMonths = 0.0;
    var currentStart = valid[0].start;
    var currentEnd = valid[0].end;
    var currentIsIntern = valid[0].isInternship;

    for (var i = 1; i < valid.length; i++) {
      final item = valid[i];
      if (item.start.isBefore(currentEnd) || item.start.isAtSameMomentAs(currentEnd)) {
        // Overlap: extend current interval
        if (item.end.isAfter(currentEnd)) {
          currentEnd = item.end;
        }
        if (!item.isInternship) {
          currentIsIntern = false; // full-time takes precedence
        }
      } else {
        // Gap: finalize current interval
        final m = _diffMonths(currentStart, currentEnd);
        totalMonths += currentIsIntern ? (m * internshipWeight) : m;
        currentStart = item.start;
        currentEnd = item.end;
        currentIsIntern = item.isInternship;
      }
    }

    final m = _diffMonths(currentStart, currentEnd);
    totalMonths += currentIsIntern ? (m * internshipWeight) : m;

    return totalMonths.round();
  }

  static double _diffMonths(DateTime start, DateTime end) {
    final years = end.year - start.year;
    final months = end.month - start.month;
    final days = (end.day - start.day) / 30.0;
    final total = (years * 12) + months + days;
    return total > 0 ? total : 1.0;
  }
}
