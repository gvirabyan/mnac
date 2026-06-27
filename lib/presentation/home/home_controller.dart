import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/service_progress.dart';
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

/// Loads the motivational Armenian quotes from the bundled asset once.
final quotesProvider = FutureProvider<List<String>>((ref) async {
  final raw = await rootBundle.loadString('assets/quotes/quotes_hy.json');
  return (jsonDecode(raw) as List).cast<String>();
});
