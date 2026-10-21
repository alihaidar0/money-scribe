import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/password_problem.dart';

/// The wait to show when the server answers `429` without `Retry-After`, which
/// the contract says it never does. It is only a safety net for a server that
/// breaks the contract: every real wait comes from the answer.
const missingRetryAfter = Duration(seconds: 30);

/// What an answer of the server means for each call, in the exceptions the
/// screens already know. The code of the error decides, never its text.

/// The answers every call can get: a wait (`429`), a busy server (`503`), a
/// lost connection, or a failure.
Exception mapCommonFailure(ApiFailure failure) {
  if (failure.statusCode == 429) {
    return RateLimitedException(
      _reason(failure.code),
      failure.retryAfter ?? missingRetryAfter,
    );
  }
  return failure.toDataException();
}

/// Sign in: `401 invalid_credentials` (an unknown email and a wrong password
/// look the same), `403 email_not_verified` (only after the right password),
/// `429 sign_in_locked` or `throttled`.
Exception mapSignInFailure(ApiFailure failure) {
  switch (failure.statusCode) {
    case 401 || 400:
      // `400` is an empty or malformed field: nothing to show but the same
      // refusal.
      return const WrongCredentialsException();
    case 403 when failure.hasCode('email_not_verified'):
      return const EmailNotVerifiedException();
  }
  return mapCommonFailure(failure);
}

/// Register: `400` field errors (the password codes, an email that is not an
/// address, a name that is empty or too long), `429` for the same address
/// again inside the wait.
Exception mapRegisterFailure(ApiFailure failure) {
  if (failure.statusCode == 400) {
    final password = _passwordProblem(failure);
    final emailInvalid = failure.forField('email') != null;
    final nameInvalid = failure.forField('name') != null;
    if (password == null && !emailInvalid && !nameInvalid) {
      return const ServerException();
    }
    return RegistrationRejectedException(
      password: password,
      emailInvalid: emailInvalid,
      nameInvalid: nameInvalid,
    );
  }
  return mapCommonFailure(failure);
}

/// Verify email: `400 code_invalid` (with `attempts_left`) or `code_expired`,
/// `429 code_attempts_exceeded` (the code is dead) or `throttled`.
Exception mapVerifyFailure(ApiFailure failure) {
  if (failure.statusCode == 400) {
    if (failure.hasCode('code_expired')) return const CodeExpiredException();
    return WrongCodeException(failure.first?.attemptsLeft);
  }
  return mapCommonFailure(failure);
}

RateLimitReason _reason(String? code) {
  return switch (code) {
    'sign_in_locked' => RateLimitReason.signInLocked,
    'resend_too_soon' => RateLimitReason.resendTooSoon,
    'resend_limit_reached' => RateLimitReason.resendLimitReached,
    'code_attempts_exceeded' => RateLimitReason.codeAttemptsExceeded,
    _ => RateLimitReason.throttled,
  };
}

/// The refusal of the password, if the answer has one. The server owns the
/// policy: the app words it, and takes the limit from the answer.
PasswordProblem? _passwordProblem(ApiFailure failure) {
  final item =
      failure.forField('password') ??
      failure.items
          .where((error) => error.code.startsWith('password_'))
          .firstOrNull;
  if (item == null) return null;

  return switch (item.code) {
    'password_too_short' => PasswordProblem(
      PasswordIssue.tooShort,
      limit: item.minLength,
    ),
    'password_too_long' => PasswordProblem(
      PasswordIssue.tooLong,
      limit: item.maxLength,
    ),
    'password_too_similar' => const PasswordProblem(PasswordIssue.tooSimilar),
    'password_too_common' => const PasswordProblem(PasswordIssue.tooCommon),
    'password_compromised' => const PasswordProblem(PasswordIssue.compromised),
    // A reason this version does not know shows the server's English text.
    _ => PasswordProblem(PasswordIssue.other, detail: item.detail),
  };
}
