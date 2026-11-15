import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/song.dart';
import '../home/home_controller.dart';

/// Today's song for everyone, or null while none was ever set. Follows
/// [epochDayProvider], so at midnight it switches to the new day's song;
/// a song set during the day shows up live.
final songOfTheDayProvider = StreamProvider.autoDispose<Song?>((ref) {
  // Only to rebuild at midnight; the day itself is read from the clock.
  ref.watch(epochDayProvider);
  return ref.watch(songOfTheDayRepositoryProvider).watchFor(DateTime.now());
});
