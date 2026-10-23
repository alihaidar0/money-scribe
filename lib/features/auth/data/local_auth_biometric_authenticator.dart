import 'package:local_auth/local_auth.dart';
import 'package:money_scribe/features/auth/domain/biometric_authenticator.dart';

/// The fingerprint or face check through the system (`local_auth`: the
/// Android BiometricPrompt, the iOS Local Authentication framework).
class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  new([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
      // A platform that cannot answer is as good as no sensor.
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // The device PIN or pattern is not this app's lock: the app has its own
        // PIN as the way in when the biometric does not work.
        biometricOnly: true,
      );
      // Cancelled, locked out by the system, or nothing enrolled: the person
      // uses the PIN.
    } on Exception {
      return false;
    }
  }
}
