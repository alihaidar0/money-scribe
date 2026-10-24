import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/lock_timeout.dart';
import 'package:money_scribe/features/auth/domain/pin_check.dart';

/// An app lock that answers at once and keeps everything in memory: a
/// fingerprint that is there, switched on and matching or not as the test
/// says, a PIN that can be set, and answers to the next PIN checks the test
/// can queue.
class InstantAppLockRepository implements AppLockRepository {
  new({
    this.deviceHasFingerprint = true,
    this.biometricsOn = true,
    this.biometricsMatch = true,
    this.pin,
    this.pause,
    this.account,
  });

  /// The device has a fingerprint the person enrolled.
  bool deviceHasFingerprint;

  /// The person turned the fingerprint switch on.
  bool biometricsOn;

  /// The fingerprint matches when asked.
  bool biometricsMatch;
  String? pin;

  /// The account the lock belongs to.
  String? account;

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
  Future<bool> biometricsAvailable() async => deviceHasFingerprint;

  @override
  Future<bool> canUseBiometrics() async {
    return deviceHasFingerprint && biometricsOn;
  }

  @override
  Future<bool> biometricsEnabled() async => biometricsOn;

  @override
  Future<bool> confirmBiometrics({required String reason}) async {
    biometricReasons.add(reason);
    return deviceHasFingerprint && biometricsMatch;
  }

  @override
  Future<bool> enableConfirmedBiometrics() async {
    if (pin == null || !deviceHasFingerprint) return false;
    biometricsOn = true;
    return true;
  }

  @override
  Future<bool> enableBiometrics({required String reason}) async {
    biometricReasons.add(reason);
    if (pin == null || !deviceHasFingerprint || !biometricsMatch) return false;
    biometricsOn = true;
    return true;
  }

  @override
  Future<void> disableBiometrics() async {
    biometricsOn = false;
  }

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
  Future<void> savePin(String pin, {String? accountId}) async {
    this.pin = pin;
    account = accountId;
  }

  @override
  Future<String?> boundAccount() async => account;

  @override
  Future<void> bindToAccount(String accountId) async {
    account = accountId;
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
    account = null;
    biometricsOn = false;
  }
}
