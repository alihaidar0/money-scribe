/// The app lock: the fingerprint and the 4-digit PIN that open the app again.
abstract interface class AppLockRepository {
  /// Asks the device to check the fingerprint.
  Future<bool> unlockWithBiometrics();

  /// Whether [pin] is the saved PIN.
  Future<bool> verifyPin(String pin);

  /// Saves [pin] and turns the app lock on.
  Future<void> savePin(String pin);

  /// Whether the app lock is on.
  Future<bool> isEnabled();

  /// Turns the app lock off and forgets the PIN.
  Future<void> disable();
}
