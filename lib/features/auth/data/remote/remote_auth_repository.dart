import 'dart:async';

import 'package:dio/dio.dart';
import 'package:money_scribe/core/api/export.dart';
import 'package:money_scribe/core/device/device_info.dart';
import 'package:money_scribe/core/device/time_zone_source.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/session_tokens.dart';
import 'package:money_scribe/core/network/token_store.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/features/auth/data/remote/remote_auth_errors.dart';
import 'package:money_scribe/features/auth/domain/account_profile.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';

/// The account on the server: the real [AuthRepository].
///
/// The session tokens live in the secure storage; this class never keeps them
/// itself. Every wait it reports comes from an answer of the server
/// (`Retry-After`, `resend_available_in`), counted down with the clock.
/// Resetting or changing a password and deleting the account are not built on
/// the server yet and fail with [FeatureNotAvailableException].
class RemoteAuthRepository implements AuthRepository {
  new({
    required this._plain,
    required this._authenticated,
    required this._tokens,
    required this._device,
    required this._timeZone,
    required this._language,
    this._clock = const SystemClock(),
  });

  /// The client that sends no token: register, sign in, the code calls, the
  /// refresh and the sign-out.
  final AuthClient _plain;

  /// The client that sends the token and renews it: the profile.
  final AuthClient _authenticated;

  final TokenStore _tokens;
  final DeviceInfoSource _device;
  final TimeZoneSource _timeZone;

  /// The language of the app now: `en` or `ar`.
  final String Function() _language;

  final Clock _clock;

  final _signedInChanges = StreamController<bool>.broadcast(sync: true);

  bool _isSignedIn = false;
  String? _pendingEmail;
  DateTime? _resendAvailableAt;
  DateTime? _lockedUntil;

  @override
  bool get isSignedIn => _isSignedIn;

  @override
  Stream<bool> get signedInChanges => _signedInChanges.stream;

  @override
  String? get pendingEmail => _pendingEmail;

  @override
  Duration get resendWaitRemaining =>
      _remaining(_resendAvailableAt) ?? Duration.zero;

  @override
  Duration? get signInLockRemaining => _remaining(_lockedUntil);

  /// Reads the session of the last run from the secure storage. No network:
  /// the app starts on the right screen at once. Call it before `runApp`.
  Future<void> restore() async {
    _setSignedIn(value: await _tokens.read() != null);
  }

  /// Asks the server about the restored session, once, in the background. A
  /// session the server ended (or a refresh it refused) signs the person out;
  /// a lost connection keeps them signed in.
  Future<void> validateSession() async {
    if (!_isSignedIn) return;
    try {
      await profile();
    } on Exception {
      // Offline or a failing server: the session may well be fine.
    }
  }

  /// Called when the server ended the session (the tokens are already
  /// cleared): the person has to sign in again.
  void sessionEnded(String? code) => _setSignedIn(value: false);

  /// Trades a refresh token for a new pair. Used by the session handling of
  /// the HTTP client; it throws the [DioException] of a failed call as it is.
  Future<SessionTokens> refreshSession(String refreshToken) async {
    final answer = await _plain.authRefresh(
      body: RefreshRequest(
        refreshToken: refreshToken,
        device: await _deviceRequest(),
      ),
    );
    return _tokensOf(answer.accessToken, answer.refreshToken);
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
    String? challengeToken,
  }) async {
    final body = SignInRequest(
      email: email,
      // Sent as typed: never trimmed, never checked against a policy.
      password: password,
      device: await _deviceRequest(),
      language: _languageEnum(),
      timeZone: await _timeZone.read(),
      captchaToken: challengeToken,
    );
    final answer = await _call(
      () => _plain.authSignIn(body: body),
      mapSignInFailure,
      onFailure: (failure, exception) {
        if (exception is RateLimitedException &&
            exception.reason == RateLimitReason.signInLocked) {
          _lockedUntil = _clock.now().add(exception.retryAfter);
        }
        if (exception is EmailNotVerifiedException) {
          // Nothing was sent: the person asks for a code on the next screen.
          _pendingEmail = email.trim();
          _resendAvailableAt = null;
        }
      },
    );
    await _startSession(answer.accessToken, answer.refreshToken);
    _lockedUntil = null;
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final body = RegisterRequest(
      name: name,
      email: email,
      password: password,
      language: _languageEnum(),
      timeZone: await _timeZone.read(),
    );
    final answer = await _call(
      () => _plain.authRegister(body: body),
      mapRegisterFailure,
    );
    // The answer is the same for a new, a pending and a registered address.
    _pendingEmail = answer.email;
    _setResendWait(answer.resendAvailableIn);
  }

  @override
  Future<void> verifyCode(CodePurpose purpose, String code) async {
    _requireEmailPurpose(purpose);
    final email = _pendingEmail;
    // No address to verify: the code cannot be valid.
    if (email == null) throw const CodeExpiredException();

    final body = VerifyEmailRequest(
      email: email,
      // Text, so a leading zero survives.
      code: code,
      device: await _deviceRequest(),
      language: _languageEnum(),
      timeZone: await _timeZone.read(),
    );
    final answer = await _call(
      () => _plain.authVerifyEmail(body: body),
      mapVerifyFailure,
      onFailure: (failure, exception) {
        if (exception is RateLimitedException &&
            exception.reason == RateLimitReason.codeAttemptsExceeded) {
          // The code is dead: the wait is the time until a new one.
          _resendAvailableAt = _clock.now().add(exception.retryAfter);
        }
      },
    );
    await _startSession(answer.accessToken, answer.refreshToken);
    _pendingEmail = null;
    _resendAvailableAt = null;
  }

  @override
  Future<void> resendCode(CodePurpose purpose) async {
    _requireEmailPurpose(purpose);
    final email = _pendingEmail;
    if (email == null) throw const CodeExpiredException();

    final answer = await _call(
      () => _plain.authResendCode(body: ResendCodeRequest(email: email)),
      mapCommonFailure,
      onFailure: (failure, exception) {
        if (exception is RateLimitedException) {
          _resendAvailableAt = _clock.now().add(exception.retryAfter);
        }
      },
    );
    _setResendWait(answer.resendAvailableIn);
  }

  @override
  Future<void> requestPasswordReset(String email) => _notAvailable();

  @override
  Future<void> resetPassword(String newPassword) => _notAvailable();

  @override
  Future<void> signOut() async {
    final tokens = await _tokens.read();
    if (tokens != null) {
      try {
        // The refresh token in the body ends the session even when the access
        // token has run out, and an ended session answers 204: no refresh
        // first. No access token is sent.
        await _plain.authSignOut(
          body: SignOutRequest(refreshToken: tokens.refreshToken),
        );
      } on Object {
        // Whatever the answer (or none), the person is signed out here: the
        // session on the server ends by itself in time.
      }
    }
    await _tokens.clear();
    _setSignedIn(value: false);
  }

  @override
  Future<AccountProfile> profile() async {
    final profile = await _call(_authenticated.authProfile, mapCommonFailure);
    return AccountProfile(name: profile.name, email: profile.email);
  }

  @override
  Future<void> changePassword({
    required String current,
    required String next,
  }) => _notAvailable();

  @override
  Future<void> deleteAccount({required String password}) => _notAvailable();

  /// Runs a call and turns its failure into the exceptions of the screens.
  /// [onFailure] sees the failure and its exception first, to remember what the
  /// server said (a wait, an address).
  Future<T> _call<T>(
    Future<T> Function() request,
    Exception Function(ApiFailure failure) map, {
    void Function(ApiFailure failure, Exception exception)? onFailure,
  }) async {
    try {
      return await request();
    } on DioException catch (error) {
      final failure = ApiFailure.from(error);
      final exception = map(failure);
      onFailure?.call(failure, exception);
      throw exception;
    } on FormatException {
      // An answer that is not what the contract says.
      throw const ServerException();
      // A body of another shape fails inside the generated `fromJson` with a
      // `TypeError`: it is the same thing, an answer that is not the contract.
      // ignore: avoid_catching_errors
    } on TypeError {
      throw const ServerException();
    }
  }

  Future<void> _startSession(String access, String? refresh) async {
    final tokens = _tokensOf(access, refresh);
    await _tokens.write(tokens);
    _setSignedIn(value: true);
  }

  /// On a phone the refresh token comes in the body: without it the session
  /// could not be kept.
  SessionTokens _tokensOf(String access, String? refresh) {
    if (refresh == null || refresh.isEmpty) {
      throw const ServerException();
    }
    return SessionTokens(accessToken: access, refreshToken: refresh);
  }

  Future<DeviceRequest> _deviceRequest() async {
    final info = await _device.read();
    return DeviceRequest(
      deviceId: info.deviceId,
      deviceName: info.deviceName,
      platform: switch (info.platform) {
        DevicePlatform.android => PlatformEnum.android,
        DevicePlatform.ios => PlatformEnum.ios,
      },
      osVersion: info.osVersion,
      appVersion: info.appVersion,
    );
  }

  LanguageEnum _languageEnum() {
    return _language() == 'ar' ? LanguageEnum.ar : LanguageEnum.en;
  }

  void _setResendWait(int seconds) {
    _resendAvailableAt = _clock.now().add(Duration(seconds: seconds));
  }

  Duration? _remaining(DateTime? until) {
    if (until == null) return null;
    final remaining = until.difference(_clock.now());
    return remaining > Duration.zero ? remaining : null;
  }

  /// A failed future, never a throw: these calls are not built on the server
  /// yet, and a caller that awaits them gets the exception like any other.
  Future<void> _notAvailable() {
    return Future<void>.error(const FeatureNotAvailableException());
  }

  void _requireEmailPurpose(CodePurpose purpose) {
    if (purpose == CodePurpose.resetPassword) {
      throw const FeatureNotAvailableException();
    }
  }

  void _setSignedIn({required bool value}) {
    if (_isSignedIn == value) return;
    _isSignedIn = value;
    _signedInChanges.add(value);
  }
}
