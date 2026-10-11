import 'dart:async';

import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

/// An account that lives in memory, until the server exists. It accepts any
/// email and password and any code, unless the demo panel says otherwise (see
/// [DemoSettings]), so every screen of the flow can be reached.
class FakeAuthRepository implements AuthRepository {
  new({required this._demo, this._now = DateTime.now, bool signedIn = false})
    : _isSignedIn = signedIn;

  /// Wrong passwords before sign-in is locked.
  static const maxSignInAttempts = 5;
  static const signInLockDuration = Duration(minutes: 5);

  /// Wrong codes before the code expires.
  static const maxCodeAttempts = 3;

  final DemoController _demo;
  final DateTime Function() _now;
  final _signedInChanges = StreamController<bool>.broadcast(sync: true);

  bool _isSignedIn;
  // A sample address, so the code screens have one to show when they are
  // opened from the demo panel; registering or resetting replaces it.
  String? _pendingEmail = 'alex@example.com';
  int _wrongPasswords = 0;
  DateTime? _lockedUntil;
  int _wrongCodes = 0;

  // The demo outcomes the counters above were counted for: a new outcome
  // starts counting again.
  DemoSignIn? _countedSignIn;
  DemoCode? _countedCode;

  @override
  bool get isSignedIn => _isSignedIn;

  @override
  Stream<bool> get signedInChanges => _signedInChanges.stream;

  @override
  String? get pendingEmail => _pendingEmail;

  @override
  Duration? get signInLockRemaining {
    _restartCountsOnNewOutcome();
    final lockedUntil = _lockedUntil;
    if (lockedUntil == null) return null;
    final remaining = lockedUntil.difference(_now());
    return remaining > Duration.zero ? remaining : null;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _demo.simulateRequest();
    final locked = signInLockRemaining;
    if (locked != null) throw TooManyAttemptsException(locked);

    switch (_demo.settings.signIn) {
      case DemoSignIn.accepted:
        _wrongPasswords = 0;
        // An existing account has data.
        if (_demo.settings.scenario == DemoScenario.empty) {
          _demo.update(_demo.settings.copyWith(scenario: DemoScenario.normal));
        }
        _setSignedIn(value: true);
      case DemoSignIn.wrongPassword:
        _wrongPasswords++;
        if (_wrongPasswords >= maxSignInAttempts) {
          _lockedUntil = _now().add(signInLockDuration);
          throw const TooManyAttemptsException(signInLockDuration);
        }
        throw const WrongCredentialsException();
      case DemoSignIn.locked:
        _lockedUntil = _now().add(signInLockDuration);
        throw const TooManyAttemptsException(signInLockDuration);
    }
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _demo.simulateRequest();
    if (_demo.settings.registration == DemoRegistration.rejected) {
      throw const RegistrationRejectedException({
        RegistrationProblem.emailTaken,
        RegistrationProblem.passwordTooShort,
        RegistrationProblem.passwordsDoNotMatch,
      });
    }
    _pendingEmail = email;
    _wrongCodes = 0;
    // A new account has no data yet: the app shows its first-launch screens.
    _demo.update(_demo.settings.copyWith(scenario: DemoScenario.empty));
  }

  @override
  Future<void> verifyCode(CodePurpose purpose, String code) async {
    await _demo.simulateRequest();
    _restartCountsOnNewOutcome();

    switch (_demo.settings.code) {
      case DemoCode.accepted:
        _wrongCodes = 0;
        if (purpose == CodePurpose.verifyEmail) _setSignedIn(value: true);
      case DemoCode.wrong:
        _wrongCodes++;
        final attemptsLeft = maxCodeAttempts - _wrongCodes;
        if (attemptsLeft <= 0) throw const CodeExpiredException();
        throw WrongCodeException(attemptsLeft);
      case DemoCode.expired:
        throw const CodeExpiredException();
    }
  }

  @override
  Future<void> resendCode(CodePurpose purpose) async {
    await _demo.simulateRequest();
    _wrongCodes = 0;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _demo.simulateRequest();
    _pendingEmail = email;
    _wrongCodes = 0;
  }

  @override
  Future<void> resetPassword(String newPassword) async {
    await _demo.simulateRequest();
  }

  @override
  Future<void> signOut() async {
    _setSignedIn(value: false);
  }

  void _setSignedIn({required bool value}) {
    if (_isSignedIn == value) return;
    _isSignedIn = value;
    _signedInChanges.add(value);
  }

  void _restartCountsOnNewOutcome() {
    final settings = _demo.settings;
    if (_countedSignIn != settings.signIn) {
      _countedSignIn = settings.signIn;
      _wrongPasswords = 0;
      _lockedUntil = null;
    }
    if (_countedCode != settings.code) {
      _countedCode = settings.code;
      _wrongCodes = 0;
    }
  }
}
