import 'package:intl/intl.dart';

/// Date formatting helpers using the Armenian locale.
abstract final class AppDateUtils {
  AppDateUtils._();

  static const String locale = 'hy';

  /// Armenian month names (nominative).
  static const List<String> monthNames = [
    'Հունվար',
    'Փետրվար',
    'Մարտ',
    'Ապրիլ',
    'Մայիս',
    'Հունիս',
    'Հուլիս',
    'Օգոստոս',
    'Սեպտեմբեր',
    'Հոկտեմբեր',
    'Նոյեմբեր',
    'Դեկտեմբեր',
  ];

  /// Short Armenian weekday names, Monday-first.
  static const List<String> weekdayShort = [
    'Երկ',
    'Երք',
    'Չրք',
    'Հնգ',
    'Ուր',
    'Շբթ',
    'Կիր',
  ];

  /// Strips time, returning the date at local midnight.
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Adds [months] calendar months to [date], clamping the day to the target
  /// month's length and preserving the time of day.
  static DateTime addMonths(DateTime date, int months) {
    final totalMonths = date.month - 1 + months;
    final year = date.year + (totalMonths ~/ 12);
    final month = (totalMonths % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day < lastDay ? date.day : lastDay;
    return DateTime(year, month, day, date.hour, date.minute, date.second);
  }

  /// e.g. "5 Մարտ 2026".
  static String formatLong(DateTime d) =>
      '${d.day} ${monthNames[d.month - 1]} ${d.year}';

  /// e.g. "Մարտ 2026".
  static String formatMonthYear(DateTime d) =>
      '${monthNames[d.month - 1]} ${d.year}';

  /// e.g. "05.03.2026".
  static String formatNumeric(DateTime d) =>
      DateFormat('dd.MM.yyyy').format(d);

  /// e.g. "08:30".
  static String formatTime(DateTime d) => DateFormat('HH:mm').format(d);

  /// Whole calendar days between two dates (ignoring time of day).
  static int daysBetween(DateTime from, DateTime to) =>
      dateOnly(to).difference(dateOnly(from)).inDays;
}
