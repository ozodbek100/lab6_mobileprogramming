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