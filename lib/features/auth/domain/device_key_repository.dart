import 'package:money_scribe/features/auth/domain/device_key.dart';

/// Signing in with the fingerprint of this phone, instead of the password.
/// The phone keeps a key pair in its secure hardware and the server keeps the
/// public half; a signed one-time challenge proves the phone holds the key.
///
/// Every method can throw a `DataException` when the server cannot be reached,
/// fails or is busy, and an `AuthException` for what the person can act on
/// (`FingerprintCancelledException`, `FingerprintUnavailableException`,
/// `FingerprintKeyInvalidatedException`, `FingerprintRefusedException`,
/// `WrongCredentialsException`, `RateLimitedException`).
abstract interface class DeviceKeyRepository {
  /// Whether this phone can hold the key.
  Future<DeviceKeySupport> support();

  /// Whether fingerprint sign-in is on for the signed-in account on this
  /// phone: it has a key that still works, and the server still knows it.
  Future<bool> isEnabled();

  /// Turns it on: makes a key in the phone's secure hardware, asks for the
  /// fingerprint (showing [prompt]) to prove the key is held, and registers
  /// the public half with the password of the account. Nothing is kept when
  /// any step fails.
  Future<void> enable({required String password, required String prompt});

  /// Turns it off: the server forgets the key, then the phone deletes it. The
  /// key stays when the server cannot be reached.
  Future<void> disable();

  /// The account this phone signs in with the fingerprint, or `null` when it
  /// is off. Works while signed out.
  Future<FingerprintAccount?> signInAccount();

  /// Signs in with the fingerprint: asks for it (showing [prompt]), signs the
  /// server's challenge and starts the session. A `FingerprintRefusedException`
  /// with `signInFailed` means the password is the way in.
  Future<void> signIn({required String prompt});

  /// Compares the phone with the server, after a sign-in: a key the server no
  /// longer knows (the password was changed, the key expired, another phone
  /// removed it) is deleted here, and so is a key of another account. Never
  /// throws: a server that cannot be reached leaves things as they are.
  Future<void> sync();

  /// Deletes the key of this phone and the account saved next to it, without
  /// telling the server: for an account that is gone with all its keys (the
  /// server deletes them with the account). Never throws.
  Future<void> forgetLocal();

  /// The phones that can sign the account in, the newest first.
  Future<List<DeviceKeyEntry>> keys();

  /// Removes the key of another phone (or this one) from the server.
  Future<void> removeKey(String deviceId);
}
