import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3.x moved StateProvider to the legacy import.
import 'package:flutter_riverpod/legacy.dart';
import '../models/tick.dart';
import '../services/tick_feed.dart';

/// When non-null, the feed throws after this many ticks (error demo).
final failAfterProvider = StateProvider<int?>((ref) => null);

/// Overridable in tests and in the error demo.
final tickFeedProvider = Provider<TickFeed>((ref) {
  return TickFeed(failAfter: ref.watch(failAfterProvider));
});

final tickerProvider = StreamProvider.autoDispose<List<Tick>>(
  (ref) => ref.watch(tickFeedProvider).watch(),
  // Riverpod 3 retries failed providers automatically; turn that off
  // so the error banner stays visible.
  retry: (retryCount, error) => null,
);