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

/// Sign in: `400 captcha_required` or `captcha_invalid` (the bot challenge,
/// asked for before the email is looked up), `401 email_not_registered` (the
/// email is checked first),
/// `401 wrong_password`, `401 invalid_credentials` for any other refusal,
/// `403 email_not_verified` (only after the right password),
/// `429 sign_in_locked` or `throttled`.
Exception mapSignInFailure(ApiFailure failure) {
  switch (failure.statusCode) {
    case 400 when failure.hasCode('captcha_required'):
      return const ChallengeRequiredException();
    case 400 when failure.hasCode('captcha_invalid'):
      return const ChallengeRejectedException();
    case 401 when failure.hasCode('email_not_registered'):
      return const EmailNotRegisteredException();
    case 401 when failure.hasCode('wrong_password'):
      return const WrongPasswordException();
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

/// Set the new password after a password reset: `400 reset_token_invalid`
/// (ask for a new code), or a refused password (`password_*`, the token stays
/// valid), `429 throttled`.
Exception mapPasswordResetConfirmFailure(ApiFailure failure) {
  if (failure.statusCode == 400) {
    if (failure.hasCode('reset_token_invalid')) {
      return const ResetTokenInvalidException();
    }
    final problem = _passwordProblem(failure);
    if (problem != null) return PasswordRejectedException(problem);
    return const ServerException();
  }
  return mapCommonFailure(failure);
}

/// Change the password: `400 invalid_password` (the current password is
/// wrong, `attr` `current_password`: a `400`, so the session handling is not
/// triggered), `400 password_unchanged` or another refused new password
/// (`password_*`), `429 password_attempts_exceeded` (5 wrong current passwords
/// lock this and the account deletion) or `throttled`.
Exception mapChangePasswordFailure(ApiFailure failure) {
  if (failure.statusCode == 400) {
    if (failure.hasCode('invalid_password')) {
      return const WrongCredentialsException();
    }
    final problem = _passwordProblem(failure);
    if (problem != null) return PasswordRejectedException(problem);
    return const ServerException();
  }
  return mapCommonFailure(failure);
}

/// Delete the account: `400 invalid_password` (the password is wrong, `attr`
/// `password`), `429 password_attempts_exceeded` (the lock it shares with
/// changing the password) or `throttled`.
Exception mapDeleteAccountFailure(ApiFailure failure) {
  if (failure.statusCode == 400) {
    if (failure.hasCode('invalid_password')) {
      return const WrongCredentialsException();
    }
    return const ServerException();
  }
  return mapCommonFailure(failure);
}

/// Edit the name: `400` on the field `name` (`blank` or `required` for an
/// empty name, `max_length` for a name that is too long).
Exception mapUpdateNameFailure(ApiFailure failure) {
  if (failure.statusCode == 400) {
    final item = failure.forField('name');
    if (item == null) return const ServerException();
    return NameRejectedException(switch (item.code) {
      'blank' || 'required' || 'null' => NameIssue.blank,
      'max_length' => NameIssue.tooLong,
      _ => NameIssue.invalid,
    });
  }
  return mapCommonFailure(failure);
}

/// Start an email change: `400 invalid_password` (the current password is
/// wrong, `attr` `current_password`), `400 email_unchanged` or another refusal
/// of the address (`attr` `email`), `409 email_already_registered`, and the
/// waits (`429`: the password lock, `resend_too_soon`, `resend_limit_reached`,
/// `throttled`).
Exception mapEmailChangeRequestFailure(ApiFailure failure) {
  if (failure.statusCode == 400) {
    if (failure.hasCode('invalid_password')) {
      return const WrongCredentialsException();
    }
    if (failure.hasCode('email_unchanged')) {
      return const EmailChangeRejectedException(EmailIssue.unchanged);
    }
    if (failure.forField('email') != null) {
      return const EmailChangeRejectedException(EmailIssue.invalid);
    }
    return const ServerException();
  }
  if (failure.statusCode == 409 &&
      failure.hasCode('email_already_registered')) {
    return const EmailChangeRejectedException(EmailIssue.taken);
  }
  return mapCommonFailure(failure);
}

/// Confirm an email change: the codes of [mapVerifyFailure], and
/// `409 email_already_registered` when the address was taken meanwhile (the
/// code is kept).
Exception mapEmailChangeConfirmFailure(ApiFailure failure) {
  if (failure.statusCode == 409 &&
      failure.hasCode('email_already_registered')) {
    return const EmailChangeRejectedException(EmailIssue.taken);
  }
  return mapVerifyFailure(failure);
}

RateLimitReason _reason(String? code) {
  return switch (code) {
    'sign_in_locked' => RateLimitReason.signInLocked,
    'resend_too_soon' => RateLimitReason.resendTooSoon,
    'resend_limit_reached' => RateLimitReason.resendLimitReached,
    'code_attempts_exceeded' => RateLimitReason.codeAttemptsExceeded,
    'password_attempts_exceeded' => RateLimitReason.passwordAttemptsExceeded,
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
    'password_unchanged' => const PasswordProblem(PasswordIssue.unchanged),
    // A reason this version does not know shows the server's English text.
    _ => PasswordProblem(PasswordIssue.other, detail: item.detail),
  };
}
