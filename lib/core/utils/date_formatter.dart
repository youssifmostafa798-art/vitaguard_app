import 'package:intl/intl.dart';

String formatChatTime(DateTime dateTime) {
  final now = DateTime.now();
  final localDateTime = dateTime.toLocal();
  final isToday = localDateTime.year == now.year &&
      localDateTime.month == now.month &&
      localDateTime.day == now.day;

  if (isToday) {
    return DateFormat('hh:mm a').format(localDateTime);
  } else {
    return DateFormat('dd MMM, hh:mm a').format(localDateTime);
  }
}

String parseAndFormatChatTime(String timeStr) {
  if (timeStr.isEmpty) return '';

  // Handle mock static relative times natively fallback
  final lowerStr = timeStr.toLowerCase();
  if (lowerStr.contains('now') ||
      lowerStr.contains('min') ||
      lowerStr.contains('hour') ||
      lowerStr.contains('ago')) {
    // If it's a relative time like "28min", treat it as today since it's mock
    return formatChatTime(DateTime.now());
  }

  // If already formatted like "hh:mm a"
  if (lowerStr.contains('am') || lowerStr.contains('pm')) {
    return timeStr;
  }

  try {
    final dateTime = DateTime.parse(timeStr);
    return formatChatTime(dateTime);
  } catch (e) {
    return timeStr;
  }
}
