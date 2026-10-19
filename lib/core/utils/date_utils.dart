import 'package:intl/intl.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';

/// Date formatting helpers in the app's current language.
abstract final class AppDateUtils {
  AppDateUtils._();

  /// Month names (nominative) in the current language.
  static List<String> get monthNames => switch (AppStrings.language) {
        AppLanguage.hy => _monthsHy,
        AppLanguage.ru => _monthsRu,
        AppLanguage.en => _monthsEn,
      };

  /// Short weekday names, Monday-first, in the current language.
  static List<String> get weekdayShort => switch (AppStrings.language) {
        AppLanguage.hy => _weekdaysHy,
        AppLanguage.ru => const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
        AppLanguage.en => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      };

  static const List<String> _monthsHy = [
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

  static const List<String> _monthsRu = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  /// Russian months after a day number: "5 марта".
  static const List<String> _monthsRuGenitive = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  static const List<String> _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> _weekdaysHy = [
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

  /// e.g. "5 Մարտ 2026", "5 марта 2026", "5 March 2026".
  static String formatLong(DateTime d) {
    final month = AppStrings.language == AppLanguage.ru
        ? _monthsRuGenitive[d.month - 1]
        : monthNames[d.month - 1];
    return '${d.day} $month ${d.year}';
  }

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
