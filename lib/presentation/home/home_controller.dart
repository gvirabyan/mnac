import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/l10n/app_language.dart';
import '../../domain/entities/service_progress.dart';
import '../shared/state/settings_controller.dart';
import '../shared/state/soldiers_controller.dart';

/// Emits the current time once per second to drive the live countdown.
final clockProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

/// The live [ServiceProgress] snapshot, recomputed each tick.
///
/// Returns null only if there is no profile (shouldn't happen inside the shell).
final serviceProgressProvider = Provider.autoDispose<ServiceProgress?>((ref) {
  final profile = ref.watch(activeSoldierProvider);
  if (profile == null) return null;

  final now = ref.watch(clockProvider).value ?? DateTime.now();
  return ref.watch(computeServiceProgressProvider)(profile, now);
});

/// Reads the motivational quotes for [language] from the bundled asset.
Future<List<String>> loadQuotes(AppLanguage language) async {
  final raw =
      await rootBundle.loadString('assets/quotes/quotes_${language.id}.json');
  return (jsonDecode(raw) as List).cast<String>();
}

/// Quotes main() read before the first frame, so the home quote shows at
/// once. Null when that failed.
final preloadedQuotesProvider =
    Provider<({AppLanguage language, List<String> quotes})?>((ref) => null);

/// The motivational quotes in the current language. Returns the preloaded
/// list synchronously when it matches, and loads the asset otherwise.
final quotesProvider = FutureProvider<List<String>>((ref) {
  final language =
      ref.watch(settingsControllerProvider.select((s) => s.language));
  final preloaded = ref.watch(preloadedQuotesProvider);
  if (preloaded != null && preloaded.language == language) {
    return preloaded.quotes;
  }
  return loadQuotes(language);
});

/// Ordinal of the current local day. Emits immediately, then re-emits just
/// after each local midnight so date-derived UI (the daily quote) advances at
/// 00:00 without needing an app restart.
final epochDayProvider = StreamProvider.autoDispose<int>((ref) async* {
  yield _dayOrdinal(DateTime.now());
  while (true) {
    final now = DateTime.now();
    final nextMidnight =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    // Small cushion past midnight to avoid landing on 23:59:59 due to drift.
    await Future<void>.delayed(
      nextMidnight.difference(now) + const Duration(seconds: 1),
    );
    yield _dayOrdinal(DateTime.now());
  }
});

/// Whole local days since a fixed reference; increments by one each day.
int _dayOrdinal(DateTime t) =>
    DateTime(t.year, t.month, t.day).difference(DateTime(2000)).inDays;

/// The motivational quote for today. Picked deterministically from the day
/// ordinal so it is stable within a day and advances to the next quote at each
/// midnight, cycling through the list.
final quoteOfTheDayProvider = Provider.autoDispose<String?>((ref) {
  final quotes = ref.watch(quotesProvider).value;
  if (quotes == null || quotes.isEmpty) return null;
  final day = ref.watch(epochDayProvider).value ?? _dayOrdinal(DateTime.now());
  return quotes[day % quotes.length];
});
