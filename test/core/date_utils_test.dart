import 'package:depitun/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('daysBetween counts calendar days whatever the time of day', () {
    // The soldier form's default start is "now", with hours and minutes; a
    // discharge picked in the calendar is a midnight. 1 Sep -> 1 Mar 2028 is
    // 547 days, not the 546 that elapsed-time rounding gave.
    expect(
      AppDateUtils.daysBetween(
        DateTime(2026, 9, 1, 14, 35),
        DateTime(2028, 3, 1),
      ),
      547,
    );
    expect(
      AppDateUtils.daysBetween(DateTime(2026, 3, 1), DateTime(2026, 11, 1)),
      245,
    );
  });
}
