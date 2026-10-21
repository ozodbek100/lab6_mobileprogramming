import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tick.dart';
import '../services/tick_feed.dart';

/// Overridable in tests and in the error demo.
final tickFeedProvider = Provider<TickFeed>((ref) => TickFeed());

final tickerProvider = StreamProvider.autoDispose<List<Tick>>(
  (ref) => ref.watch(tickFeedProvider).watch(),
  // Riverpod 3 retries failed providers automatically; turn that off
  // so errors stay visible in Part 4.
  retry: (retryCount, error) => null,
);