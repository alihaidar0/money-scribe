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
