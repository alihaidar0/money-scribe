/// The fingerprint or face check of the device. The app never sees the
/// biometric data: the system answers whether it matched.
abstract interface class BiometricAuthenticator {
  /// Whether the device can check a biometric right now: it has the sensor and
  /// the person has enrolled one.
  Future<bool> isAvailable();

  /// Asks the system to check the biometric, showing [reason]. `false` when it
  /// did not match, was cancelled, or cannot be used at the moment; the PIN is
  /// the way in then. Never falls back to the device PIN or pattern.
  Future<bool> authenticate({required String reason});
}
