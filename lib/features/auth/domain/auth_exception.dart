import 'package:money_scribe/features/auth/domain/password_problem.dart';

/// Why sign-in, registration or a code check was refused. These are answers of
/// the server the person can act on; a lost connection or a server failure is a
/// `DataException` instead.
sealed class AuthException implements Exception {
  const new();
}

/// The email or the password is wrong.
final class WrongCredentialsException extends AuthException {
  const new();

  @override
  String toString() => 'WrongCredentialsException';
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
