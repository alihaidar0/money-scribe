import 'dart:async';

import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/device/device_info.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/device_key.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';

/// Fingerprint sign-in that lives in memory, for a build with no server and
/// for the emulator, which has no secure hardware to make a key in. It follows
/// the demo panel: the phone without a fingerprint, a fingerprint that does
/// not match, a key the server refuses, a locked or failing sign-in.
class FakeDeviceKeyRepository implements DeviceKeyRepository {
  new({required this._demo, required this._auth, this._now = DateTime.now});

  /// The id the fake gives this phone in the list.
  static const thisDeviceId = 'fake-this-phone';

  static const lockDuration = Duration(minutes: 5);

  final DemoController _demo;
  final FakeAuthRepository _auth;
  final DateTime Function() _now;

  final _changes = StreamController<void>.broadcast();

  FingerprintAccount? _account;
  DateTime? _enabledAt;

  /// The password version the key was made under: a password change or reset
  /// ends it, as the server removes every key then.
  var _passwordVersion = 0;

  /// The phones the sample account turned the sign-in on for before this one.
  late final _others = <DeviceKeyEntry>[
    DeviceKeyEntry(
      id: 'fake-key-1',
      deviceId: 'fake-other-android',
      deviceName: 'Galaxy S24',
      platform: DevicePlatform.android,
      attested: true,
      isCurrent: false,
      createdAt: _now().subtract(const Duration(days: 12)),
      lastUsedAt: _now().subtract(const Duration(days: 2)),
      expiresAt: _now().add(const Duration(days: 28)),
    ),
    DeviceKeyEntry(
      id: 'fake-key-2',
      deviceId: 'fake-other-ios',
      deviceName: 'iPhone 15',
      platform: DevicePlatform.ios,
      attested: false,
      isCurrent: false,
      createdAt: _now().subtract(const Duration(days: 40)),
      expiresAt: _now().add(const Duration(days: 5)),
    ),
  ];

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<DeviceKeySupport> support() async {
    return switch (_demo.settings.fingerprint) {
      DemoFingerprint.notEnrolled => DeviceKeySupport.notEnrolled,
      DemoFingerprint.unsupported => DeviceKeySupport.unsupported,
      _ => DeviceKeySupport.available,
    };
  }

  @override
  Future<bool> isEnabled() async {
    final account = _account;
    return account != null && account.accountId == _auth.accountId && !_isStale;
  }

  /// Whether the password changed since the key was made, which the server
  /// answers by removing the key.
  bool get _isStale => _passwordVersion != _auth.passwordVersion;

  @override
  Future<void> enable({
    required String password,
    required String prompt,
  }) async {
    await _demo.simulateRequest();
    if (await support() != DeviceKeySupport.available) {
      throw const FingerprintUnavailableException();
    }
    switch (_demo.settings.fingerprint) {
      case DemoFingerprint.notMatched:
        throw const FingerprintCancelledException();
      case DemoFingerprint.attestationRefused:
        throw const FingerprintRefusedException(FingerprintRefusal.attestation);
      case DemoFingerprint.limitReached:
        throw const FingerprintRefusedException(
          FingerprintRefusal.limitReached,
        );
      case DemoFingerprint.unavailable:
        throw const ServiceUnavailableException();
      case DemoFingerprint.accepted ||
          DemoFingerprint.signInRefused ||
          DemoFingerprint.locked ||
          DemoFingerprint.notEnrolled ||
          DemoFingerprint.unsupported:
        break;
    }
    if (_demo.settings.signIn == DemoSignIn.wrongPassword) {
      throw const WrongCredentialsException();
    }

    final profile = await _auth.profile();
    _account = FingerprintAccount(
      accountId: _auth.accountId ?? 'demo-account',
      name: profile.name,
      maskedEmail: maskEmail(profile.email),
    );
    _enabledAt = _now();
    _passwordVersion = _auth.passwordVersion;
    _changes.add(null);
  }

  @override
  Future<void> disable() async {
    await _demo.simulateSave();
    _forget();
  }

  @override
  Future<FingerprintAccount?> signInAccount() async => _account;

  @override
  Future<void> signIn({required String prompt}) async {
    await _demo.simulateRequest();
    switch (_demo.settings.fingerprint) {
      case DemoFingerprint.notMatched:
        throw const FingerprintCancelledException();
      case DemoFingerprint.signInRefused:
        throw const FingerprintRefusedException(
          FingerprintRefusal.signInFailed,
        );
      case DemoFingerprint.locked:
        throw const RateLimitedException(
          RateLimitReason.signInLocked,
          lockDuration,
        );
      case DemoFingerprint.unavailable:
        throw const ServiceUnavailableException();
      case DemoFingerprint.notEnrolled || DemoFingerprint.unsupported:
        throw const FingerprintUnavailableException();
      case DemoFingerprint.accepted ||
          DemoFingerprint.attestationRefused ||
          DemoFingerprint.limitReached:
        break;
    }
    if (_account == null || _isStale) {
      throw const FingerprintRefusedException(FingerprintRefusal.signInFailed);
    }
    await _auth.signInWithFingerprint();
  }

  @override
  Future<void> sync() async {
    final account = _account;
    if (account != null && (account.accountId != _auth.accountId || _isStale)) {
      // Another account signed in on this phone, or the server removed the key
      // when the password changed.
      _forget();
    }
  }

  @override
  Future<void> forgetLocal() async {
    _forget();
  }

  @override
  Future<List<DeviceKeyEntry>> keys() async {
    await _demo.simulateRequest();
    final enabledAt = _enabledAt;
    return [
      if (await isEnabled() && enabledAt != null)
        DeviceKeyEntry(
          id: 'fake-key-this',
          deviceId: thisDeviceId,
          deviceName: 'Pixel 8',
          platform: DevicePlatform.android,
          attested: true,
          isCurrent: true,
          createdAt: enabledAt,
          expiresAt: enabledAt.add(const Duration(days: 30)),
        ),
      ..._others,
    ];
  }

  @override
  Future<void> removeKey(String deviceId) async {
    await _demo.simulateSave();
    if (deviceId == thisDeviceId) _forget();
    _others.removeWhere((entry) => entry.deviceId == deviceId);
  }

  /// This phone has no key any more, and the screens are told.
  void _forget() {
    _account = null;
    _enabledAt = null;
    _changes.add(null);
  }
}
