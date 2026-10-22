import 'dart:async';

import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/domain/account_profile.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/password_problem.dart';

/// An account that lives in memory, until the server exists. It accepts any
/// email and password and any code, unless the demo panel says otherwise (see
/// [DemoSettings]), so every screen of the flow can be reached. It answers the
/// way the server does: the same waits, the same refusals.
class FakeAuthRepository implements AuthRepository {
  new({required this._demo, this._now = DateTime.now, bool signedIn = false})
    : _isSignedIn = signedIn;

  /// Wrong passwords before sign-in is locked.
  static const maxSignInAttempts = 5;
  static const signInLockDuration = Duration(minutes: 5);

  /// Wrong codes before the code is dead.
  static const maxCodeAttempts = 5;

  /// How long a new code cannot be asked for after one was sent.
  static const resendWait = Duration(seconds: 60);

  /// The shortest password the demo server accepts, to show its message.
  static const demoMinimumPasswordLength = 15;

  final DemoController _demo;
  final DateTime Function() _now;
  final _signedInChanges = StreamController<bool>.broadcast(sync: true);

  bool _isSignedIn;
  // A sample address, so the code screens have one to show when they are
  // opened from the demo panel; registering or resetting replaces it.
  String? _pendingEmail = 'alex@example.com';
  DateTime? _resendAvailableAt;
  // The sample account the demo opens with; registering or signing in with
  // another address replaces it.
  AccountProfile _profile = const AccountProfile(
    name: 'Alex',
    email: 'alex@example.com',
  );
  int _wrongPasswords = 0;
  DateTime? _lockedUntil;
  int _wrongCodes = 0;
  bool _codeDead = false;

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
  Duration get resendWaitRemaining {
    final availableAt = _resendAvailableAt;
    if (availableAt == null) return Duration.zero;
    final remaining = availableAt.difference(_now());
    return remaining > Duration.zero ? remaining : Duration.zero;
  }

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
    if (locked != null) {
      throw RateLimitedException(RateLimitReason.signInLocked, locked);
    }

    switch (_demo.settings.signIn) {
      case DemoSignIn.accepted:
        _wrongPasswords = 0;
        _useAccount(email);
        // An existing account has data.
        if (_demo.settings.scenario == DemoScenario.empty) {
          _demo.update(_demo.settings.copyWith(scenario: DemoScenario.normal));
        }
        _setSignedIn(value: true);
      case DemoSignIn.wrongPassword:
        _wrongPasswords++;
        if (_wrongPasswords >= maxSignInAttempts) {
          _lockedUntil = _now().add(signInLockDuration);
          throw const RateLimitedException(
            RateLimitReason.signInLocked,
            signInLockDuration,
          );
        }
        throw const WrongPasswordException();
      case DemoSignIn.emailNotRegistered:
        throw const EmailNotRegisteredException();
      case DemoSignIn.locked:
        _lockedUntil = _now().add(signInLockDuration);
        throw const RateLimitedException(
          RateLimitReason.signInLocked,
          signInLockDuration,
        );
      case DemoSignIn.emailNotVerified:
        // No code is sent by the sign-in: the person asks for one.
        _pendingEmail = email.trim();
        _resendAvailableAt = null;
        _wrongCodes = 0;
        _codeDead = false;
        throw const EmailNotVerifiedException();
      case DemoSignIn.unavailable:
        throw const ServiceUnavailableException();
    }
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _demo.simulateRequest();
    switch (_demo.settings.registration) {
      case DemoRegistration.accepted:
        break;
      case DemoRegistration.rejected:
        throw const RegistrationRejectedException(
          password: PasswordProblem(
            PasswordIssue.tooShort,
            limit: demoMinimumPasswordLength,
          ),
          emailInvalid: true,
        );
      case DemoRegistration.tooSoon:
        throw const RateLimitedException(
          RateLimitReason.resendTooSoon,
          resendWait,
        );
      case DemoRegistration.unavailable:
        throw const ServiceUnavailableException();
    }

    // The wait is kept per address, like the server does: the same address
    // again inside it is refused, whatever the answer was before.
    final address = email.trim().toLowerCase();
    final wait = resendWaitRemaining;
    if (wait > Duration.zero && address == _pendingEmail?.toLowerCase()) {
      throw RateLimitedException(RateLimitReason.resendTooSoon, wait);
    }

    _pendingEmail = email.trim();
    _resendAvailableAt = _now().add(resendWait);
    _profile = AccountProfile(name: name.trim(), email: email.trim());
    _wrongCodes = 0;
    _codeDead = false;
    // A new account has no data yet: the app shows its first-launch screens.
    _demo.update(_demo.settings.copyWith(scenario: DemoScenario.empty));
  }

  @override
  Future<void> verifyCode(CodePurpose purpose, String code) async {
    await _demo.simulateRequest();
    _restartCountsOnNewOutcome();

    switch (_demo.settings.code) {
      case DemoCode.accepted:
        if (_codeDead) throw const CodeExpiredException();
        _wrongCodes = 0;
        if (purpose == CodePurpose.verifyEmail) _setSignedIn(value: true);
      case DemoCode.wrong:
        if (_codeDead) throw const CodeExpiredException();
        _wrongCodes++;
        final attemptsLeft = maxCodeAttempts - _wrongCodes;
        if (attemptsLeft <= 0) {
          _killCode();
          throw const RateLimitedException(
            RateLimitReason.codeAttemptsExceeded,
            resendWait,
          );
        }
        throw WrongCodeException(attemptsLeft);
      case DemoCode.expired:
        throw const CodeExpiredException();
      case DemoCode.attemptsExceeded:
        _killCode();
        throw const RateLimitedException(
          RateLimitReason.codeAttemptsExceeded,
          resendWait,
        );
      case DemoCode.unavailable:
        throw const ServiceUnavailableException();
    }
  }

  @override
  Future<void> resendCode(CodePurpose purpose) async {
    await _demo.simulateRequest();
    if (_demo.settings.code == DemoCode.unavailable) {
      throw const ServiceUnavailableException();
    }
    final wait = resendWaitRemaining;
    if (wait > Duration.zero) {
      throw RateLimitedException(RateLimitReason.resendTooSoon, wait);
    }
    _startNewCode();
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _demo.simulateRequest();
    _pendingEmail = email;
    _startNewCode();
  }

  @override
  Future<void> resetPassword(String newPassword) async {
    await _demo.simulateRequest();
  }

  @override
  Future<void> signOut() async {
    _setSignedIn(value: false);
  }

  @override
  Future<AccountProfile> profile() async {
    await _demo.simulateRequest();
    return _profile;
  }

  @override
  Future<void> changePassword({
    required String current,
    required String next,
  }) async {
    await _demo.simulateSave();
    _requireRightPassword();
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    await _demo.simulateSave();
    _requireRightPassword();
    // Nothing of the account is left: the next one starts empty.
    _demo.update(_demo.settings.copyWith(scenario: DemoScenario.normal));
    _setSignedIn(value: false);
  }

  /// The fake server does not know the password: it is wrong when the demo
  /// panel says the next sign-in has a wrong password.
  void _requireRightPassword() {
    if (_demo.settings.signIn == DemoSignIn.wrongPassword) {
      throw const WrongCredentialsException();
    }
  }

  /// A new code replaces every earlier one, and a new wait starts.
  void _startNewCode() {
    _resendAvailableAt = _now().add(resendWait);
    _wrongCodes = 0;
    _codeDead = false;
  }

  /// Too many wrong codes: the code is dead, and a new one can be asked for
  /// once the wait is over.
  void _killCode() {
    _codeDead = true;
    _resendAvailableAt = _now().add(resendWait);
  }

  /// Signs in as [email]: the sample account keeps its name, any other address
  /// gets a name made from it.
  void _useAccount(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty ||
        trimmed.toLowerCase() == _profile.email.toLowerCase()) {
      return;
    }
    final local = trimmed.split('@').first;
    _profile = AccountProfile(
      name: local.isEmpty
          ? _profile.name
          : '${local[0].toUpperCase()}${local.substring(1)}',
      email: trimmed,
    );
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
      _codeDead = false;
    }
  }
}
