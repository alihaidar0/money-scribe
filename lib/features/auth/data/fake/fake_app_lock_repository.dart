import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';

/// An app lock that lives in memory, until the real one exists. The
/// fingerprint always matches. Before a PIN is saved, any PIN opens the app.
class FakeAppLockRepository implements AppLockRepository {
  new();

  String? _pin;

  @override
  Future<bool> unlockWithBiometrics() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<bool> verifyPin(String pin) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _pin == null || _pin == pin;
  }

  @override
  Future<void> savePin(String pin) async {
    _pin = pin;
  }
}
