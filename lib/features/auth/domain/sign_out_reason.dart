/// Why the server signed this device out, so the Sign in screen can say it.
/// The person's own sign-out has no reason.
enum SignOutReason {
  /// The account signed in on more devices than it may, so the server ended
  /// the session used least recently: this one.
  tooManyDevices,

  /// The person ended this session from another device.
  endedElsewhere,

  /// The password of the account was changed or reset.
  passwordChanged,

  /// The email address of the account was changed.
  emailChanged,

  /// The server ended the session to protect the account (a refresh token was
  /// used twice).
  security,

  /// The session ran out: unused for too long, or at its time limit.
  expired,

  /// Any other reason, or one this version of the app does not know.
  other,
}
