/// How the email change ended, passed back from screen to screen so the
/// Account screen knows whether to show the new address.
enum EmailChangeOutcome {
  /// The code was confirmed: the account has its new address.
  changed,

  /// The person cancelled the pending change.
  cancelled,
}
