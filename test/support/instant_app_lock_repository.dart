import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/lock_timeout.dart';
import 'package:money_scribe/features/auth/domain/pin_check.dart';

/// An app lock that answers at once and keeps everything in memory: a
/// fingerprint that is there and matches or not as the test says, a PIN that
/// can be set, and answers to the next PIN checks the test can queue.
class InstantAppLockRepository implements AppLockRepository {
  new({
    this.biometricsAvailable = true,
    this.biometricsMatch = true,
    this.pin,
    this.pause,
  });

  bool biometricsAvailable;
  bool biometricsMatch;
  String? pin;

  /// A pause after wrong PINs that is running now.
  Duration? pause;

  /// The answers of the next calls of [checkPin], used first.
  final queuedChecks = <PinCheck>[];

  /// What was asked: the reasons given to the fingerprint dialog.
  final biometricReasons = <String>[];

  LockTimeout currentTimeout = LockTimeout.standard;

  /// How many times the app lock was turned off.
  int disabledCount = 0;

  @override
  Future<bool> canUseBiometrics() async => biometricsAvailable;

  @override
  Future<bool> unlockWithBiometrics({required String reason}) async {
    biometricReasons.add(reason);
    return biometricsMatch;
  }

  @override
  Future<PinCheck> checkPin(String pin) async {
    if (queuedChecks.isNotEmpty) return queuedChecks.removeAt(0);
    return this.pin == null || this.pin == pin
        ? const PinAccepted()
        : const PinWrong();
  }

  @override
  Future<Duration?> pinPauseRemaining() async => pause;

  @override
  Future<void> savePin(String pin) async {
    this.pin = pin;
  }

  @override
  Future<bool> isEnabled() async => pin != null;

  @override
  Future<LockTimeout> timeout() async => currentTimeout;

  @override
  Future<void> setTimeout(LockTimeout timeout) async {
    currentTimeout = timeout;
  }

  @override
  Future<void> disable() async {
    disabledCount++;
    pin = null;
  }
}
