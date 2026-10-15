import 'package:money_scribe/core/time/clock.dart';

/// A clock that stands still at the time the test says.
class FixedClock implements Clock {
  new(this.time);

  DateTime time;

  @override
  DateTime now() => time;
}
