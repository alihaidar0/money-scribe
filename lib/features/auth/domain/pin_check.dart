/// What checking a typed PIN found.
sealed class PinCheck {
  const new();
}

/// The PIN is the saved one.
final class PinAccepted extends PinCheck {
  const new();
}

/// The PIN is not the saved one. [delay] is the pause that this wrong PIN
/// started, when it started one: no PIN is checked until it ends.
final class PinWrong extends PinCheck {
  const new({this.delay});

  final Duration? delay;
}

/// A pause after wrong PINs is still running, so the PIN was not even checked.
final class PinPaused extends PinCheck {
  const new(this.remaining);

  final Duration remaining;
}

/// Too many wrong PINs in a row: the PIN is no longer a way in, and only the
/// account password opens the app again.
final class PinTooManyFailures extends PinCheck {
  const new();
}
