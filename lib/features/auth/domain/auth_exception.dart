import 'package:money_scribe/features/auth/domain/password_problem.dart';

/// Why sign-in, registration or a code check was refused. These are answers of
/// the server the person can act on; a lost connection or a server failure is a
/// `DataException` instead.
sealed class AuthException implements Exception {
  const new();
}

/// The email or the password is wrong, without saying which. Sign-in answers
/// it only for a refusal that is neither of the two below (a deactivated
/// account, for instance); changing the password and deleting the account use
/// it for a wrong current password.
final class WrongCredentialsException extends AuthException {
  const new();

  @override
  String toString() => 'WrongCredentialsException';
}

/// Sign-in: no account has this email address. The server checks the email
/// first, so this is the only answer for an unknown address.
final class EmailNotRegisteredException extends AuthException {
  const new();

  @override
  String toString() => 'EmailNotRegisteredException';
}

/// Sign-in: the account exists but the password is wrong.
final class WrongPasswordException extends AuthException {
  const new();

  @override
  String toString() => 'WrongPasswordException';
}

/// Sign-in: the server wants a solved bot challenge before it looks at the
/// email and password (after repeated failed sign-ins from one address). The
/// same sign-in is sent again with the token of the solved challenge.
final class ChallengeRequiredException extends AuthException {
  const new();

  @override
  String toString() => 'ChallengeRequiredException';
}

/// Sign-in: the token of the challenge was refused (wrong, expired after five
/// minutes, or already used). A new challenge gives a new token.
final class ChallengeRejectedException extends AuthException {
  const new();

  @override
  String toString() => 'ChallengeRejectedException';
}

/// The password is right but the email address was never verified: the person
/// has to type the code sent to it. Nothing was sent by the sign-in itself.
final class EmailNotVerifiedException extends AuthException {
  const new();

  @override
  String toString() => 'EmailNotVerifiedException';
}

/// Why the server asked the person to wait.
enum RateLimitReason {
  /// Sign-in is locked after too many wrong passwords. It stays locked even
  /// for the right password.
  signInLocked,

  /// A new code was asked for too soon after the last one.
  resendTooSoon,

  /// Too many new codes were asked for within the hour.
  resendLimitReached,

  /// Too many wrong codes: the code is dead and a new one is needed.
  codeAttemptsExceeded,

  /// Too many wrong current passwords: changing the password and deleting
  /// the account are locked for a while. Signing in is not affected.
  passwordAttemptsExceeded,

  /// Too many requests from this device or network.
  throttled,
}

/// The server refused the request for now, and said for how long.
final class RateLimitedException extends AuthException {
  const new(this.reason, this.retryAfter);

  final RateLimitReason reason;

  /// How long until the same request may be made again (`Retry-After`).
  final Duration retryAfter;

  @override
  String toString() => 'RateLimitedException($reason)';
}

/// The data of a new account was refused. A server that refuses nothing about
/// a field leaves it out.
final class RegistrationRejectedException extends AuthException {
  const new({
    this.password,
    this.emailInvalid = false,
    this.nameInvalid = false,
  });

  /// What was wrong with the password, if anything.
  final PasswordProblem? password;

  /// The email address is not valid.
  final bool emailInvalid;

  /// The name is empty or too long.
  final bool nameInvalid;

  @override
  String toString() => 'RegistrationRejectedException';
}

/// The code is wrong. [attemptsLeft] tells how many tries remain when the
/// server says so.
final class WrongCodeException extends AuthException {
  const new([this.attemptsLeft]);

  final int? attemptsLeft;

  @override
  String toString() => 'WrongCodeException';
}

/// The code is no longer valid: it is too old, or no code was ever sent to
/// this address. A new one has to be asked for.
final class CodeExpiredException extends AuthException {
  const new();

  @override
  String toString() => 'CodeExpiredException';
}

/// The new password was refused (resetting or changing a password): [problem]
/// says why.
/// The server owns the password policy; the app only words it.
final class PasswordRejectedException extends AuthException {
  const new(this.problem);

  final PasswordProblem problem;

  @override
  String toString() => 'PasswordRejectedException';
}

/// The reset cannot go on: its token is unknown, was used, or ran out, or the
/// app lost it. A new code has to be asked for from the start.
final class ResetTokenInvalidException extends AuthException {
  const new();

  @override
  String toString() => 'ResetTokenInvalidException';
}

/// Why the server refused a new name.
enum NameIssue {
  /// Empty, or only spaces.
  blank,

  /// Longer than the server accepts.
  tooLong,

  /// Any other refusal of the name.
  invalid,
}

/// The new display name was refused: [issue] says why. The name stays as it
/// was.
final class NameRejectedException extends AuthException {
  const new(this.issue);

  final NameIssue issue;

  @override
  String toString() => 'NameRejectedException($issue)';
}

/// Why the server refused the new email address of an email change.
enum EmailIssue {
  /// It is the address the account already has.
  unchanged,

  /// Not an email address.
  invalid,

  /// Another account uses it.
  taken,
}

/// The new email address was refused: [issue] says why. The account keeps its
/// address.
final class EmailChangeRejectedException extends AuthException {
  const new(this.issue);

  final EmailIssue issue;

  @override
  String toString() => 'EmailChangeRejectedException($issue)';
}

/// Why the fingerprint sign-in could not be turned on or used. These are
/// answers the person can act on; a lost connection is a `DataException`.
enum FingerprintRefusal {
  /// The phone's key could not be vouched for (an emulator, a rooted phone, an
  /// unlocked bootloader, a build the server does not know). The server gives
  /// no reason, on purpose.
  attestation,

  /// This kind of session cannot hold a key (the web).
  platform,

  /// The challenge ran out (it lives two minutes) or the proof was wrong: ask
  /// again.
  challenge,

  /// The key was not a key the server can use.
  publicKey,

  /// The account already has five phones with fingerprint sign-in.
  limitReached,

  /// Signing in with the fingerprint was refused, for any reason: the key is
  /// unknown or expired, or the challenge ran out. The password is the way in.
  signInFailed,
}

/// The server refused the device key: [reason] says why.
final class FingerprintRefusedException extends AuthException {
  const new(this.reason);

  final FingerprintRefusal reason;

  @override
  String toString() => 'FingerprintRefusedException($reason)';
}

/// The person cancelled the fingerprint check, or it did not match. Nothing
/// is said to them: they can simply try again.
final class FingerprintCancelledException extends AuthException {
  const new();

  @override
  String toString() => 'FingerprintCancelledException';
}

/// The phone cannot check a fingerprint now: none is enrolled, the sensor is
/// locked after too many tries, or the phone has no secure hardware.
final class FingerprintUnavailableException extends AuthException {
  const new();

  @override
  String toString() => 'FingerprintUnavailableException';
}

/// The key stopped working because a fingerprint was added or removed on the
/// phone, which is what the key is built to do. The key is gone from the
/// phone: the person turns the sign-in on again with the password.
final class FingerprintKeyInvalidatedException extends AuthException {
  const new();

  @override
  String toString() => 'FingerprintKeyInvalidatedException';
}
