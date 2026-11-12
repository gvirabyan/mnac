import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/l10n/app_language.dart';
import '../../core/utils/daily_quote.dart';
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

/// This install's seed for the order of the daily quotes, made once at
/// random and kept, so each phone gets its own order (see [DailyQuote]).
final quoteSeedProvider = Provider<int>((ref) {
  const key = 'daily_quote_seed';
  final prefs = ref.watch(sharedPreferencesProvider);
  final saved = prefs.getInt(key);
  if (saved != null) return saved;
  final seed = Random().nextInt(1 << 31);
  prefs.setInt(key, seed);
  return seed;
});

/// Ordinal of the current local day. Emits immediately, then re-emits just
/// after each local midnight so date-derived UI (the daily quote) advances at
/// 00:00 without needing an app restart.
final epochDayProvider = StreamProvider.autoDispose<int>((ref) async* {
  yield DailyQuote.dayOrdinal(DateTime.now());
  while (true) {
    final now = DateTime.now();
    final nextMidnight =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    // Small cushion past midnight to avoid landing on 23:59:59 due to drift.
    await Future<void>.delayed(
      nextMidnight.difference(now) + const Duration(seconds: 1),
    );
    yield DailyQuote.dayOrdinal(DateTime.now());
  }
});

/// The motivational quote for today: stable within a day, the next one at
/// each midnight, in this install's own random order (see [DailyQuote]).
final quoteOfTheDayProvider = Provider.autoDispose<String?>((ref) {
  final quotes = ref.watch(quotesProvider).value;
  if (quotes == null || quotes.isEmpty) return null;
  final day = ref.watch(epochDayProvider).value ??
      DailyQuote.dayOrdinal(DateTime.now());
  return DailyQuote.pick(quotes, day, ref.watch(quoteSeedProvider));
});
