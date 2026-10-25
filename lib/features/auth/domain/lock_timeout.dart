/// How long the app may stay in the background before it asks for the PIN or
/// the fingerprint again. A new lock asks every time the app comes back from
/// the background, so a phone put down is never an open app; the person can
/// allow a short stay, for example to read an email code in another app.
enum LockTimeout {
  /// As soon as the app leaves the screen.
  immediately(Duration.zero),

  thirtySeconds(Duration(seconds: 30)),

  oneMinute(Duration(minutes: 1)),

  fiveMinutes(Duration(minutes: 5));

  new(this.duration);

  /// The time in the background after which the app is locked.
  final Duration duration;

  /// What a new lock starts with.
  static const LockTimeout standard = immediately;
}
