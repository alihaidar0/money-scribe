import 'package:money_scribe/core/time/clock.dart';

/// A clock that stands still at the time the test says.
class FixedClock implements Clock {
  new(this.time);

  DateTime time;

  @override
  DateTime now() => time;
}

/// A monotonic clock that stands still until the test moves it.
class FixedMonotonicClock implements MonotonicClock {
  Duration time = Duration.zero;

  @override
  Duration elapsed() => time;
}
