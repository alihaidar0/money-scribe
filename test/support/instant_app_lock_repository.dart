import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';

/// An app lock that answers at once, with a fingerprint that matches or not
/// as the test says, and a PIN that can be set.
class InstantAppLockRepository implements AppLockRepository {
  new({this.biometricsMatch = true, this.pin});

  bool biometricsMatch;
  String? pin;

  @override
  Future<bool> unlockWithBiometrics() async => biometricsMatch;

  @override
  Future<bool> verifyPin(String pin) async =>
      this.pin == null || this.pin == pin;

  @override
  Future<void> savePin(String pin) async {
    this.pin = pin;
  }
}
