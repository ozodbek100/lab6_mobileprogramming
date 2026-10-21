# Riverpod Ticker: Lab notes

## Part 2 inline questions

1. **Why is the feed behind its own Provider?**
   So it can be swapped in tests and in the error demo (`overrideWithValue`) and configured from other providers, without editing `tickerProvider`. It also gives one shared `TickFeed` instance instead of building a new one inside the stream provider.

2. **What does `autoDispose` do when the user navigates away mid-stream?**
   When the last listener goes away, the provider is disposed: the stream subscription is cancelled and its state is dropped. Coming back rebuilds it from scratch, so it starts with `AsyncLoading` again.

3. **What AsyncValue does `tickerProvider` hold during the 800 ms delay, and what is `hasValue`?**
   `AsyncLoading` with no previous value, so `hasValue` is `false`.

## Part 3 exercises

**3.3 Break the switch on purpose**
Removing the `AsyncLoading()` arm gives this analyzer error:

```
error - The type 'AsyncValue<List<Tick>>' isn't exhaustively matched by the switch
cases since it doesn't match the pattern 'AsyncLoading<List<Tick>>()'. Try adding a
wildcard pattern or cases that match 'AsyncLoading<List<Tick>>()'
- lib\ticker_page.dart:15:13 - non_exhaustive_switch_expression
```

Because `AsyncValue` is sealed, the compiler forces me to handle every state.

**3.4 Pattern-match on content**
The `AsyncData(value: [])` and `AsyncData(value: [final only])` arms must come before `AsyncData(:final value)`. Arms are checked from top to bottom, and the general arm matches every list, so the specific ones would never run (the analyzer would flag them as unreachable).

## Part 4 exercises

**4.3 refresh vs invalidate**
(Fill in what you observe in the app.) Expected: both keep the previous rows visible while reloading, because the provider moves to loading while carrying the old value. ref.refresh(tickerProvider.future) returns a Future<List<Tick>> that completes on the next emission, so the RefreshIndicator keeps spinning until new data arrives. ref.invalidate returns void and rebuilds lazily, so the indicator would finish immediately.

**4.4 Reconnect vs first load**
The AsyncValue(:final value?, isLoading: true) arm sits above AsyncData and AsyncLoading, so a retry after prices were shown gets the thin progress bar, never the full-screen spinner.
isRefreshing is a refresh that keeps its data/error subtype with isLoading: true. isReloading is an AsyncLoading that still carries a previous value or error (for example after invalidate or a dependency change).

## Checkpoint questions

1. **Which three subtypes make AsyncValue sealed, and what does the analyzer report when a switch misses one?**
   `AsyncData`, AsyncLoading and AsyncError. A switch that misses one fails analysis with non_exhaustive_switch_expression, naming the unmatched subtype.

2. **When does `AsyncError.value` carry a non-null value, and when is it null?**
   It is non-null when data existed before the error (Riverpod copies the previous value into the AsyncError). It is null when the very first load failed.

3. **Difference between `ref.refresh(provider)`, `ref.refresh(provider.future)` and `ref.invalidate(provider)`?**
   `ref.refresh(provider) invalidates and immediately re-reads, returning the new state. `ref.refresh(provider.future) does the same but returns the awaitable future of the new value. ref.invalidate(provider) only marks the provider stale and returns void; it rebuilds when it is next read or listened to.

4. **Why must `AsyncValue(:final value?, isLoading: true)` sit above `AsyncData(:final value)`?**
   A refresh can arrive as an AsyncData with isLoading: true. If AsyncData(:final value) came first it would match, and the progress bar would never show.

5. **One reason to prefer switch expressions over `.when(...)`, and one situation where `.when` is still convenient?**
   Switch expressions are checked for exhaustiveness and can pattern-match on content and conditions (value?, value: [], isLoading: true). .when is still convenient for quick one-off UI with three simple callbacks.