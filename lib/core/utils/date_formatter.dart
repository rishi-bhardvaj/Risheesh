import 'package:intl/intl.dart';

class DateFormatter {
  static String formatHeaderDate(DateTime date) {
    return DateFormat('EEEE, d MMMM').format(date);
  }

  static String formatDate(DateTime? date) {
    if (date == null) return 'No date';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return 'No date';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatShortDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM').format(date);
  }

  static String formatRelative(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = date.difference(now);
    final days = difference.inDays;

    if (days == 0 && date.day == now.day) {
      return 'Today';
    } else if (days == 1 || (days == 0 && date.day == now.day + 1)) {
      return 'Tomorrow';
    } else if (days == -1 || (days == 0 && date.day == now.day - 1)) {
      return 'Yesterday';
    } else if (days > 0 && days <= 7) {
      return 'In $days days';
    } else if (days < 0 && days >= -7) {
      return '${-days}d ago';
    } else {
      return DateFormat('dd MMM').format(date);
    }
  }

  static bool isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isOverdue(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return date.isBefore(todayStart);
  }
}

