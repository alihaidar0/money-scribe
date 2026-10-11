/// What a 4-digit code is for.
enum CodePurpose { verifyEmail, resetPassword }

/// The account of the person using the app: sign-in, registration, the 4-digit
/// codes and the session. Every method can also throw a `DataException` when
/// the server cannot be reached or fails.
abstract interface class AuthRepository {
  /// Whether a person is signed in.
  bool get isSignedIn;

  /// Emits whenever [isSignedIn] changes.
  Stream<bool> get signedInChanges;

  /// The address the last 4-digit code was sent to, if any.
  String? get pendingEmail;

  /// How long sign-in stays locked after too many wrong attempts, or `null`.
  Duration? get signInLockRemaining;

  /// Throws `WrongCredentialsException` or `TooManyAttemptsException`.
  Future<void> signIn({required String email, required String password});

  /// Creates the account and sends a code to `email`. Throws
  /// `RegistrationRejectedException`.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  /// Throws `WrongCodeException` or `CodeExpiredException`. A correct code for
  /// `CodePurpose.verifyEmail` also signs the person in.
  Future<void> verifyCode(CodePurpose purpose, String code);

  /// Sends a new code to `pendingEmail`.
  Future<void> resendCode(CodePurpose purpose);

  /// Sends a code to `email` to reset its password.
  Future<void> requestPasswordReset(String email);

  /// Sets the new password, after a correct reset code.
  Future<void> resetPassword(String newPassword);

  Future<void> signOut();
}
