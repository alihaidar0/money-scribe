/// What wrong PINs cost. A 4-digit PIN has only 10,000 possibilities, so the
/// limit on tries is what protects it, not the way it is stored.
///
/// The steps follow the escalating pauses of the phone's own lock screen: no
/// pause for the first four wrong PINs, then a pause that grows, and after
/// ten wrong PINs in a row the PIN stops being a way in (NIST SP 800-63B asks
/// for a limit of at most ten consecutive failures). A right PIN or a
/// fingerprint starts the count again.
abstract final class PinLockoutPolicy {
  /// The wrong PINs in a row after which the PIN is no longer accepted.
  static const maxFailures = 10;

  static const _pauses = <int, Duration>{
    5: Duration(seconds: 30),
    6: Duration(minutes: 1),
    7: Duration(minutes: 5),
    8: Duration(minutes: 15),
    9: Duration(minutes: 15),
  };

  /// The pause that the [failures]th wrong PIN in a row starts, or `null`
  /// when it starts none.
  static Duration? pauseAfter(int failures) => _pauses[failures];

  /// Whether [failures] wrong PINs in a row are too many.
  static bool isTooMany(int failures) => failures >= maxFailures;
}
