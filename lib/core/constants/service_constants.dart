/// Domain constants for Armenian military service.
abstract final class ServiceConstants {
  ServiceConstants._();

  /// Standard conscription length in Armenia is currently 1.5 years (18 months).
  static const int defaultServiceMonths = 18;

  /// Days added after [defaultServiceMonths] for the default discharge date:
  /// a soldier who starts on 12 Nov 2026 is discharged on 13 May 2028.
  static const int defaultServiceExtraDays = 1;

  /// Fallback duration in days (used only if a date computation is unavailable).
  static const int defaultServiceDays = 547; // ~18 months

  /// A shorter common option (e.g. higher-education track) — 12 months.
  static const int shortServiceDays = 365;

}
