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

/// Sign-in is locked for a while after too many wrong attempts.
final class TooManyAttemptsException extends AuthException {
  const new(this.retryAfter);

  final Duration retryAfter;

  @override
  String toString() => 'TooManyAttemptsException';
}

/// What was wrong with the data of a new account.
enum RegistrationProblem { emailTaken, passwordTooShort, passwordsDoNotMatch }

/// The data of a new account was refused.
final class RegistrationRejectedException extends AuthException {
  const new(this.problems);

  final Set<RegistrationProblem> problems;

  @override
  String toString() => 'RegistrationRejectedException';
}

/// The 4-digit code is wrong; [attemptsLeft] tries remain.
final class WrongCodeException extends AuthException {
  const new(this.attemptsLeft);

  final int attemptsLeft;

  @override
  String toString() => 'WrongCodeException';
}

/// The 4-digit code is no longer valid: it is too old, or was tried too often.
final class CodeExpiredException extends AuthException {
  const new();

  @override
  String toString() => 'CodeExpiredException';
}
