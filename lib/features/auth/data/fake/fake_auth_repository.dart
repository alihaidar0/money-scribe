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

  /// An address the demo server says another account already uses.
  static const demoTakenEmail = 'taken@example.com';

  /// The longest name the server accepts.
  static const demoMaximumNameLength = 100;

  final DemoController _demo;
  final DateTime Function() _now;
  final _signedInChanges = StreamController<bool>.broadcast(sync: true);

  bool _isSignedIn;

  /// How many times the password was changed or reset. Like the server, which
  /// removes every fingerprint key then, the fake key of a phone notes the
  /// number it was made under.
  int _passwordVersion = 0;

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
  // Who is signed in: a new account (registering, or signing in with another
  // address) gets a new id, a change of name or email does not.
  var _accountNumber = 1;
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
  String? get accountId => _isSignedIn ? 'demo-account-$_accountNumber' : null;

  /// How many times the password was changed or reset.
  int get passwordVersion => _passwordVersion;

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
  Future<void> signIn({
    required String email,
    required String password,
    String? challengeToken,
  }) async {
    await _demo.simulateRequest();
    final locked = signInLockRemaining;
    if (locked != null) {
      throw RateLimitedException(RateLimitReason.signInLocked, locked);
    }

    final outcome = _demo.settings.signIn;
    final asksChallenge =
        outcome == DemoSignIn.challengeRequired ||
        outcome == DemoSignIn.challengeRejected;
    // Like the server, ask before looking at the email and password.
    if (asksChallenge && challengeToken == null) {
      throw const ChallengeRequiredException();
    }

    switch (outcome) {
      case DemoSignIn.accepted || DemoSignIn.challengeRequired:
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
      case DemoSignIn.challengeRejected:
        throw const ChallengeRejectedException();
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

  /// Signs the account in the way its phone's fingerprint does: no email, no
  /// password, no bot challenge.
  Future<void> signInWithFingerprint() async {
    _wrongPasswords = 0;
    _setSignedIn(value: true);
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
    _accountNumber++;
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
        if (purpose == CodePurpose.changeEmail) _applyPendingEmailChange();
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
  Future<void> resendCode(CodePurpose purpose, {String? password}) async {
    await _demo.simulateRequest();
    if (_demo.settings.code == DemoCode.unavailable) {
      throw const ServiceUnavailableException();
    }
    if (purpose == CodePurpose.changeEmail) {
      // Like the server, a new code for an email change asks for the password
      // again, and is held back by the lock shared with changing the password.
      _requireRightPassword();
      _throwSharedPasswordFailures();
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
    if (_demo.settings.code == DemoCode.unavailable) {
      throw const ServiceUnavailableException();
    }
    // The wait is kept per address, like the server does: the same address
    // again inside it is refused.
    final wait = resendWaitRemaining;
    if (wait > Duration.zero &&
        email.trim().toLowerCase() == _pendingEmail?.toLowerCase()) {
      throw RateLimitedException(RateLimitReason.resendTooSoon, wait);
    }
    _pendingEmail = email.trim();
    _startNewCode();
  }

  @override
  Future<void> resetPassword(String newPassword) async {
    await _demo.simulateRequest();
    switch (_demo.settings.passwordReset) {
      case DemoPasswordReset.accepted:
        break;
      case DemoPasswordReset.passwordRefused:
        throw const PasswordRejectedException(
          PasswordProblem(
            PasswordIssue.tooShort,
            limit: demoMinimumPasswordLength,
          ),
        );
      case DemoPasswordReset.tokenInvalid:
        throw const ResetTokenInvalidException();
      case DemoPasswordReset.tooSoon:
        throw const RateLimitedException(
          RateLimitReason.throttled,
          Duration(seconds: 30),
        );
      case DemoPasswordReset.unavailable:
        throw const ServiceUnavailableException();
    }
    // Like the server, a reset ends every session, this one included, and
    // removes every fingerprint key.
    _passwordVersion++;
    _setSignedIn(value: false);
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
  Future<void> requestEmailChange({
    required String email,
    required String password,
  }) async {
    await _demo.simulateSave();
    _requireRightPassword();
    _throwSharedPasswordFailures();

    final address = email.trim();
    if (!_looksLikeAddress(address)) {
      throw const EmailChangeRejectedException(EmailIssue.invalid);
    }
    if (address.toLowerCase() == _profile.email.toLowerCase()) {
      throw const EmailChangeRejectedException(EmailIssue.unchanged);
    }
    if (address.toLowerCase() == demoTakenEmail) {
      throw const EmailChangeRejectedException(EmailIssue.taken);
    }
    // The wait is kept per address, like the server does: the same address
    // again inside it is refused.
    final wait = resendWaitRemaining;
    if (wait > Duration.zero &&
        address.toLowerCase() == _pendingEmail?.toLowerCase()) {
      throw RateLimitedException(RateLimitReason.resendTooSoon, wait);
    }
    _pendingEmail = address;
    _startNewCode();
  }

  @override
  Future<void> cancelEmailChange() async {
    await _demo.simulateRequest();
    _pendingEmail = null;
    _resendAvailableAt = null;
  }

  @override
  Future<AccountProfile> updateName(String name) async {
    await _demo.simulateSave();
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const NameRejectedException(NameIssue.blank);
    if (trimmed.length > demoMaximumNameLength) {
      throw const NameRejectedException(NameIssue.tooLong);
    }
    return _profile = AccountProfile(name: trimmed, email: _profile.email);
  }

  @override
  Future<void> changePassword({
    required String current,
    required String next,
  }) async {
    await _demo.simulateSave();
    _requireRightPassword();
    switch (_demo.settings.passwordChange) {
      case DemoPasswordChange.accepted:
        break;
      case DemoPasswordChange.passwordRefused:
        throw const PasswordRejectedException(
          PasswordProblem(
            PasswordIssue.tooShort,
            limit: demoMinimumPasswordLength,
          ),
        );
      case DemoPasswordChange.locked:
        throw const RateLimitedException(
          RateLimitReason.passwordAttemptsExceeded,
          Duration(minutes: 15),
        );
      case DemoPasswordChange.unavailable:
        throw const ServiceUnavailableException();
    }
    // Like the server, the new password has to differ from the current one.
    if (current == next) {
      throw const PasswordRejectedException(
        PasswordProblem(PasswordIssue.unchanged),
      );
    }
    _passwordVersion++;
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    await _demo.simulateSave();
    _requireRightPassword();
    _throwSharedPasswordFailures();
    // Nothing of the account is left: the next one starts empty.
    _accountNumber++;
    _demo.update(_demo.settings.copyWith(scenario: DemoScenario.normal));
    _setSignedIn(value: false);
  }

  /// The lock after wrong passwords and the busy server are shared by
  /// changing the password, deleting the account and changing the email, as on
  /// the server.
  void _throwSharedPasswordFailures() {
    switch (_demo.settings.passwordChange) {
      case DemoPasswordChange.locked:
        throw const RateLimitedException(
          RateLimitReason.passwordAttemptsExceeded,
          Duration(minutes: 15),
        );
      case DemoPasswordChange.unavailable:
        throw const ServiceUnavailableException();
      case DemoPasswordChange.accepted || DemoPasswordChange.passwordRefused:
        break;
    }
  }

  /// A rough check, enough for the demo to show the message for something
  /// that is not an address.
  static bool _looksLikeAddress(String value) {
    final at = value.indexOf('@');
    return at > 0 && value.indexOf('.', at) > at + 1 && !value.endsWith('.');
  }

  /// The code of an email change was right: the account has the new address.
  void _applyPendingEmailChange() {
    final address = _pendingEmail;
    if (address != null) {
      _profile = AccountProfile(name: _profile.name, email: address);
    }
    _pendingEmail = null;
    _resendAvailableAt = null;
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
    _accountNumber++;
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
