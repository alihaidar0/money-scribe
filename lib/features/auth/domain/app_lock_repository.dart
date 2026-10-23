import 'package:money_scribe/features/auth/domain/lock_timeout.dart';
import 'package:money_scribe/features/auth/domain/pin_check.dart';

/// The app lock: a 4-digit PIN and, where the device has one, the fingerprint
/// or face that open the app again. Everything is kept on the device, in the
/// platform's secure storage.
abstract interface class AppLockRepository {
  /// Whether the app lock is on: a PIN is saved.
  Future<bool> isEnabled();

  /// Saves [pin] (only a salted hash of it is kept) and turns the app lock on.
  /// The count of wrong PINs starts again.
  Future<void> savePin(String pin);

  /// Checks [pin] against the saved one and counts a wrong one (see
  /// `PinLockoutPolicy`). Nothing is checked while a pause is running.
  Future<PinCheck> checkPin(String pin);

  /// How long until a PIN is checked again, or `null` when no pause is
  /// running. Kept across restarts of the app.
  Future<Duration?> pinPauseRemaining();

  /// Whether the fingerprint (or face) can be used now.
  Future<bool> canUseBiometrics();

  /// Asks the device to check the fingerprint, showing [reason]. A match also
  /// starts the count of wrong PINs again.
  Future<bool> unlockWithBiometrics({required String reason});

  /// How long the app may stay in the background before it locks.
  Future<LockTimeout> timeout();

  Future<void> setTimeout(LockTimeout timeout);

  /// Turns the app lock off and forgets the PIN, the count of wrong PINs and
  /// the time in the background.
  Future<void> disable();
}
