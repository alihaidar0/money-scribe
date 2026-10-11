/// A countdown, injected so tests do not wait for real seconds.
abstract interface class Ticker {
  /// The seconds left, once a second: `seconds - 1`, then down to `0`.
  Stream<int> countdown(int seconds);
}

/// The real clock.
class PeriodicTicker implements Ticker {
  const new();

  @override
  Stream<int> countdown(int seconds) {
    return Stream.periodic(
      const Duration(seconds: 1),
      (count) => seconds - count - 1,
    ).take(seconds);
  }
}
