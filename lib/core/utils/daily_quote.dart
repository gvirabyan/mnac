import 'dart:math';

/// Picks the day's quote so that each install gets its own random order,
/// while staying the same all day and never repeating a quote before the
/// whole list has been shown.
///
/// The days are split into rounds as long as the list. Each round shows the
/// quotes in an order shuffled from the install's [seed] and the round
/// number, so two phones see different quotes on the same day, and each
/// round runs in a fresh order.
abstract final class DailyQuote {
  DailyQuote._();

  /// Whole calendar days since a fixed reference; increments by one each
  /// local day. Counted on UTC dates so a daylight-saving change can't skip
  /// or repeat a day.
  static int dayOrdinal(DateTime t) => DateTime.utc(t.year, t.month, t.day)
      .difference(DateTime.utc(2000))
      .inDays;

  /// The quote for [day] (a [dayOrdinal]) on the install with [seed]; null
  /// when [quotes] is empty.
  static String? pick(List<String> quotes, int day, int seed) {
    if (quotes.isEmpty) return null;
    final n = quotes.length;
    final round = day ~/ n;
    final order = List<int>.generate(n, (i) => i)
      ..shuffle(Random(seed ^ (round * 7919)));
    return quotes[order[day % n]];
  }
}
