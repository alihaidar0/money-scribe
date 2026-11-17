/// What time it is, injected so tests can say what today is.
abstract interface class Clock {
  DateTime now();
}

/// The clock of the device.
class SystemClock implements Clock {
  const new();

  @override
  DateTime now() => DateTime.now();
}

/// Time that only moves forward, whatever the person does to the date and time
/// of the phone, injected so tests can drive it.
///
/// Only the difference of two readings means something: the starting point is
/// not defined. It can stand still while the device sleeps, so a length of time
/// that matters for safety is the longer of this and the wall [Clock].
abstract interface class MonotonicClock {
  /// The time that has passed since a fixed but unspecified moment.
  Duration elapsed();
}

/// The monotonic clock of the device (`Stopwatch` runs on it in the Dart VM).
class SystemMonotonicClock implements MonotonicClock {
  const new();

  static final Stopwatch _running = Stopwatch()..start();

  @override
  Duration elapsed() => _running.elapsed;
}
