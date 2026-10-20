import 'package:money_scribe/features/auth/domain/account_profile.dart';

/// What a 6-digit code sent by email is for.
enum CodePurpose { verifyEmail, resetPassword }

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

  /// Throws `WrongCredentialsException`, `EmailNotVerifiedException` (the
  /// address becomes [pendingEmail] and no code is sent) or
  /// `RateLimitedException`. The password is sent as typed: sign-in never
  /// applies a password policy.
  Future<void> signIn({required String email, required String password});

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
  /// signs the person in. The code is text, so a leading zero survives.
  Future<void> verifyCode(CodePurpose purpose, String code);

  /// Sends a new code to `pendingEmail` and starts a new wait: read
  /// [resendWaitRemaining]. Throws `RateLimitedException`.
  Future<void> resendCode(CodePurpose purpose);

  /// Sends a code to `email` to reset its password.
  Future<void> requestPasswordReset(String email);

  /// Sets the new password, after a correct reset code.
  Future<void> resetPassword(String newPassword);

  Future<void> signOut();

  /// The name and the email of the signed-in person.
  Future<AccountProfile> profile();

  /// Sets a new password after checking the current one. Throws
  /// `WrongCredentialsException` when [current] is not the password.
  Future<void> changePassword({required String current, required String next});

  /// Deletes the account with all its data from the server and signs out.
  /// Throws `WrongCredentialsException` when [password] is not the password.
  Future<void> deleteAccount({required String password});
}
