import 'package:money_scribe/core/storage/secure_value_store.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/features/auth/data/pin_hasher.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/biometric_authenticator.dart';
import 'package:money_scribe/features/auth/domain/lock_timeout.dart';
import 'package:money_scribe/features/auth/domain/pin_check.dart';
import 'package:money_scribe/features/auth/domain/pin_lockout_policy.dart';

/// The app lock on the device. The PIN is kept as a salted hash, with the count
/// of wrong PINs, the pause they started and the lock timeout, in the
/// platform's secure storage (the Android Keystore, the iOS Keychain). The PIN
/// itself is never kept, and nothing here is sent anywhere.
///
/// A wrong PIN is counted *before* it is checked, so ending the app between
/// the two cannot give a free try. The pause is stored as a moment in time, so
/// it survives a restart; a clock set back can shorten it, but never beyond
/// the longest pause of the policy.
class SecureAppLockRepository implements AppLockRepository {
  new({
    required this._store,
    required this._biometrics,
    this._clock = const SystemClock(),
    this._hasher = const PinHasher(),
  });

  static const _pinKey = 'app_lock.pin';
  static const _failuresKey = 'app_lock.failures';
  static const _pausedUntilKey = 'app_lock.paused_until';
  static const _timeoutKey = 'app_lock.timeout';

  /// The longest pause the policy can start.
  static const _longestPause = Duration(minutes: 15);

  final SecureValueStore _store;
  final BiometricAuthenticator _biometrics;
  final Clock _clock;
  final PinHasher _hasher;

  @override
  Future<bool> isEnabled() async => (await _verifier()) != null;

  @override
  Future<void> savePin(String pin) async {
    final verifier = await _hasher.create(pin);
    await _resetCounters();
    await _store.write(_pinKey, verifier.toJson());
  }

  @override
  Future<PinCheck> checkPin(String pin) async {
    final verifier = await _verifier();
    // No saved PIN: there is no lock to open.
    if (verifier == null) return const PinAccepted();

    var failures = await _failures();
    if (PinLockoutPolicy.isTooMany(failures)) {
      return const PinTooManyFailures();
    }
    final pause = await pinPauseRemaining();
    if (pause != null) return PinPaused(pause);

    failures++;
    await _store.write(_failuresKey, '$failures');
    if (await _hasher.matches(pin, verifier)) {
      await _resetCounters();
      return const PinAccepted();
    }
    if (PinLockoutPolicy.isTooMany(failures)) {
      return const PinTooManyFailures();
    }
    final started = PinLockoutPolicy.pauseAfter(failures);
    if (started != null) {
      final until = _clock.now().add(started);
      await _store.write(
        _pausedUntilKey,
        '${until.toUtc().millisecondsSinceEpoch}',
      );
    }
    return PinWrong(delay: started);
  }

  @override
  Future<Duration?> pinPauseRemaining() async {
    final text = await _store.read(_pausedUntilKey);
    final millis = int.tryParse(text ?? '');
    if (millis == null) return null;
    final until = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    final remaining = until.difference(_clock.now().toUtc());
    if (remaining <= Duration.zero) return null;
    return remaining > _longestPause ? _longestPause : remaining;
  }

  @override
  Future<bool> canUseBiometrics() => _biometrics.isAvailable();

  @override
  Future<bool> unlockWithBiometrics({required String reason}) async {
    final matched = await _biometrics.authenticate(reason: reason);
    if (matched) await _resetCounters();
    return matched;
  }

  @override
  Future<LockTimeout> timeout() async {
    final name = await _store.read(_timeoutKey);
    return LockTimeout.values.firstWhere(
      (timeout) => timeout.name == name,
      orElse: () => LockTimeout.standard,
    );
  }

  @override
  Future<void> setTimeout(LockTimeout timeout) {
    return _store.write(_timeoutKey, timeout.name);
  }

  @override
  Future<void> disable() async {
    await _store.delete(_pinKey);
    await _resetCounters();
    await _store.delete(_timeoutKey);
  }

  Future<PinVerifier?> _verifier() async {
    return PinVerifier.tryParse(await _store.read(_pinKey));
  }

  Future<int> _failures() async {
    return int.tryParse(await _store.read(_failuresKey) ?? '') ?? 0;
  }

  Future<void> _resetCounters() async {
    await _store.delete(_failuresKey);
    await _store.delete(_pausedUntilKey);
  }
}
