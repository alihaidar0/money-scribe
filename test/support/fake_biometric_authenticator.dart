import 'package:money_scribe/features/auth/domain/biometric_authenticator.dart';

/// A fingerprint that is there or not, and matches or not, as the test says.
class FakeBiometricAuthenticator implements BiometricAuthenticator {
  new({this.available = true, this.matches = true});

  bool available;
  bool matches;

  /// The reasons the dialog was opened with.
  final reasons = <String>[];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate({required String reason}) async {
    reasons.add(reason);
    return matches;
  }
}
