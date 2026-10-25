import 'package:money_scribe/features/auth/domain/lock_timeout.dart';
import 'package:money_scribe/features/auth/domain/pin_check.dart';

/// The app lock: a 4-digit PIN and, when the person turned it on, the
/// fingerprint (or face) that opens the app again. Everything is kept on the
/// device, in the platform's secure storage, and belongs to the account that
/// set it: another account signing in on the same phone starts without a lock.
abstract interface class AppLockRepository {
  /// Whether the app lock is on: a PIN is saved.
  Future<bool> isEnabled();

  /// Saves [pin] (only a salted hash of it is kept) and turns the app lock on
  /// for the account [accountId], when it is known. The count of wrong PINs
  /// starts again.
  Future<void> savePin(String pin, {String? accountId});

  /// The account the lock belongs to, or `null` when it was saved before the
  /// account was known.
  Future<String?> boundAccount();

  /// Makes the lock belong to [accountId].
  Future<void> bindToAccount(String accountId);

  /// Checks [pin] against the saved one and counts a wrong one (see
  /// `PinLockoutPolicy`). Nothing is checked while a pause is running.
  Future<PinCheck> checkPin(String pin);

  /// How long until a PIN is checked again, or `null` when no pause is
  /// running. Kept across restarts of the app.
  Future<Duration?> pinPauseRemaining();

  /// Whether the device has a fingerprint (or face) the person enrolled, so
  /// the switch in the Settings can be turned on.
  Future<bool> biometricsAvailable();

  /// Whether the person turned the fingerprint on.
  Future<bool> biometricsEnabled();

  /// Asks the device to check the fingerprint, showing [reason], and answers
  /// whether it matched. Nothing is saved: it is the first step of turning the
  /// fingerprint on when the PIN lock is not on yet.
  Future<bool> confirmBiometrics({required String reason});

  /// Turns the fingerprint on, but only after it matched: it asks the device
  /// to check it, showing [reason], and answers whether it did. Nothing changes
  /// when it did not match, or the lock is off or the device has none.
  Future<bool> enableBiometrics({required String reason});

  /// Turns the fingerprint on for a fingerprint that was just confirmed with
  /// [confirmBiometrics] and a PIN that was just created, without asking
  /// again. Answers `false` and changes nothing when there is no PIN or the
  /// device has no fingerprint.
  Future<bool> enableConfirmedBiometrics();

  Future<void> disableBiometrics();

  /// Whether the lock screen can ask for the fingerprint: it is on, and the
  /// device still has one.
  Future<bool> canUseBiometrics();

  /// Asks the device to check the fingerprint, showing [reason]. A match also
  /// starts the count of wrong PINs again.
  Future<bool> unlockWithBiometrics({required String reason});

  /// How long the app may stay in the background before it locks.
  Future<LockTimeout> timeout();

  Future<void> setTimeout(LockTimeout timeout);

  /// Turns the app lock off and forgets the PIN, the fingerprint switch, the
  /// count of wrong PINs, the timeout and the account it belonged to.
  Future<void> disable();
}
