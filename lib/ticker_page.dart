import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/tick.dart';
import 'providers/ticker_providers.dart';
import 'widgets/tick_row.dart';

class TickerPage extends ConsumerWidget {
  const TickerPage({super.key});

  Widget _rows(List<Tick> ticks) => ListView(
        children: [for (final t in ticks) TickRow(t, key: ValueKey(t.symbol))],
      );

  /// Reset the failure toggle so the retry can succeed, then rebuild.
  void _retry(WidgetRef ref) {
    ref.read(failAfterProvider.notifier).state = null;
    ref.invalidate(tickerProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticks = ref.watch(tickerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live ticker'),
        actions: [
          IconButton(
            tooltip: 'Make feed fail after 5 ticks',
            icon: const Icon(Icons.bug_report),
            onPressed: () => ref.read(failAfterProvider.notifier).state = 5,
          ),
          IconButton(
            tooltip: 'Restore healthy feed',
            icon: const Icon(Icons.check_circle),
            onPressed: () => ref.read(failAfterProvider.notifier).state = null,
          ),
        ],
      ),
      // Arm order is a priority list: specific arms above general ones.
      body: switch (ticks) {
        // Error with stale data: dimmed rows, banner on top.
        AsyncError(:final error, :final value?) => Column(children: [
            MaterialBanner(
              content: Text('Feed error: $error — showing last prices'),
              actions: [
                TextButton(
                  onPressed: () => _retry(ref),
                  child: const Text('Retry'),
                ),
              ],
            ),
            Expanded(child: Opacity(opacity: 0.5, child: _rows(value))),
          ]),
        // Error with nothing to show.
        AsyncError(:final error) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Could not load ticker\n$error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _retry(ref),
                child: const Text('Retry'),
              ),
            ]),
          ),
        // Refresh/reload in progress with old data: keep rows, thin progress bar.
        AsyncValue(:final value?, isLoading: true) => Column(children: [
            const LinearProgressIndicator(),
            Expanded(child: _rows(value)),
          ]),
        // Content-based arms must come before the general AsyncData arm.
        AsyncData(value: []) => const Center(child: Text('No symbols subscribed')),
        AsyncData(value: [final only]) => Center(child: TickRow(only)),
        // Exercise 4.3: pull-to-refresh.
        AsyncData(:final value) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(tickerProvider),
            child: _rows(value),
          ),
        // Cold start only.
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}