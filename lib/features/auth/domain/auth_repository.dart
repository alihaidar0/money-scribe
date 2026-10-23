import 'package:money_scribe/features/auth/domain/account_profile.dart';

/// What a 6-digit code sent by email is for.
enum CodePurpose { verifyEmail, resetPassword, changeEmail }

/// The account of the person using the app: sign-in, registration, the 6-digit
/// codes and the session. Every method can also throw a `DataException` when
/// the server cannot be reached, fails, or is busy
/// (`ServiceUnavailableException`).
///
/// The server decides every wait. A repository never uses a wait of its own:
/// [resendWaitRemaining] and [signInLockRemaining] are what the server last
/// said, counted down.
abstract interface class AuthRepository {
  /// Whether a person is signed in.
  bool get isSignedIn;

  /// Emits whenever [isSignedIn] changes.
  Stream<bool> get signedInChanges;

  /// The address the last 6-digit code was sent to, if any.
  String? get pendingEmail;

  /// How long until a new code may be asked for; [Duration.zero] when it may be
  /// asked for now.
  Duration get resendWaitRemaining;

  /// How long sign-in stays locked after too many wrong attempts, or `null`.
  Duration? get signInLockRemaining;

  /// Throws `EmailNotRegisteredException`, `WrongPasswordException`,
  /// `WrongCredentialsException` (any other refusal),
  /// `EmailNotVerifiedException` (the address becomes [pendingEmail] and no
  /// code is sent) or `RateLimitedException`. The password is sent as typed:
  /// sign-in never applies a password policy.
  ///
  /// After repeated failures the server asks for a bot challenge first
  /// (`ChallengeRequiredException`); [challengeToken] is the token of the
  /// solved challenge, used once, and `ChallengeRejectedException` says it was
  /// not accepted.
  Future<void> signIn({
    required String email,
    required String password,
    String? challengeToken,
  });

  /// Creates the account and sends a code to `email`. The answer is the same
  /// for a new, a pending and an already registered address. Throws
  /// `RegistrationRejectedException`, or `RateLimitedException` when the same
  /// address was registered a moment ago.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  /// Throws `WrongCodeException`, `CodeExpiredException` or
  /// `RateLimitedException`. A correct code for `CodePurpose.verifyEmail` also
  /// signs the person in; one for `CodePurpose.changeEmail` gives the account
  /// its new address (and `EmailChangeRejectedException` says another account
  /// took it meanwhile). The code is text, so a leading zero survives.
  Future<void> verifyCode(CodePurpose purpose, String code);

  /// Sends a new code to `pendingEmail` and starts a new wait: read
  /// [resendWaitRemaining]. Throws `RateLimitedException`. Changing the email
  /// asks for the current [password] again, because the server does for every
  /// new code; the other purposes ignore it. A wrong one is
  /// `WrongCredentialsException`.
  Future<void> resendCode(CodePurpose purpose, {String? password});

  /// Sends a code to `email` to reset its password.
  Future<void> requestPasswordReset(String email);

  /// Sets the new password, after a correct reset code.
  Future<void> resetPassword(String newPassword);

  Future<void> signOut();

  /// The name and the email of the signed-in person.
  Future<AccountProfile> profile();

  /// Starts changing the sign-in address: the server emails a 6-digit code to
  /// [email], which becomes `pendingEmail`, and the account keeps its address
  /// until the code is confirmed with `verifyCode(CodePurpose.changeEmail)`.
  /// A new request replaces the one that was pending. Throws
  /// `WrongCredentialsException` (the current [password] is wrong),
  /// `EmailChangeRejectedException` or `RateLimitedException` (the password
  /// lock shared with changing the password, a code asked for too soon, too
  /// many codes).
  Future<void> requestEmailChange({
    required String email,
    required String password,
  });

  /// Drops the pending email change, so its code stops working. Does nothing
  /// when none is pending.
  Future<void> cancelEmailChange();

  /// Sets a new display name and returns the profile with it. Throws
  /// `NameRejectedException` when the server refuses the name.
  Future<AccountProfile> updateName(String name);

  /// Sets a new password after checking the current one. Throws
  /// `WrongCredentialsException` when [current] is not the password.
  Future<void> changePassword({required String current, required String next});

  /// Deletes the account with all its data from the server and signs out.
  /// Throws `WrongCredentialsException` when [password] is not the password.
  Future<void> deleteAccount({required String password});
}
