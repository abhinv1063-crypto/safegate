import 'package:intl/intl.dart';

class DateTimeFormatter {
  static String formatDateTime(
    DateTime dt, {
    bool showTime = true,
    bool relative = true,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final dtDate = DateTime(dt.year, dt.month, dt.day);

    String dateStr;

    if (relative) {
      if (dtDate == today) {
        dateStr = 'Today';
      } else if (dtDate == yesterday) {
        dateStr = 'Yesterday';
      } else if (dtDate == tomorrow) {
        dateStr = 'Tomorrow';
      } else if (now.difference(dt).inDays < 7 && dt.isAfter(now)) {
        // Future dates within a week
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        dateStr = weekdays[dt.weekday - 1];
      } else if (now.difference(dt).inDays < 7 && dt.isBefore(now)) {
        // Past dates within a week
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        dateStr = weekdays[dt.weekday - 1];
      } else {
        // Older dates
        dateStr = DateFormat('dd/MM/yyyy').format(dt);
      }
    } else {
      dateStr = DateFormat('dd/MM/yyyy').format(dt);
    }

    if (showTime) {
      final timeStr = DateFormat('HH:mm').format(dt);
      return '$dateStr $timeStr';
    } else {
      return dateStr;
    }
  }

  static String formatTimeOnly(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  static String formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return formatDateTime(dt, showTime: true, relative: true);
    }
  }

  static String formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }
}
