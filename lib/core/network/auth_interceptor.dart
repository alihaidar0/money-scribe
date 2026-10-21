import 'dart:async';

import 'package:dio/dio.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/session_tokens.dart';
import 'package:money_scribe/core/network/token_store.dart';
import 'package:money_scribe/core/time/clock.dart';

/// Trades a refresh token for a new pair. It must use a Dio of its own, with no
/// interceptors, so a refresh never waits for itself. It throws the
/// [DioException] of a failed call as it is.
typedef RefreshSession = Future<SessionTokens> Function(String refreshToken);

/// Called when the server ended the session (or refused to renew it): the
/// tokens are gone and the person has to sign in again. [code] is the error
/// code of the answer, such as `session_expired`.
typedef SessionEnded = void Function(String? code);

/// Puts the access token on requests, and keeps the session alive.
///
/// - **Only `401 token_expired` refreshes.** The request is sent again once
///   with the new token. Any other `401` on a signed-in request is final: the
///   tokens are cleared and [SessionEnded] is called.
/// - **One refresh at a time.** Requests that expire together wait for the same
///   refresh, because the refresh token is single use and two refreshes with
///   the same token end the session. A request that was sent with an older
///   access token than the stored one is sent again without refreshing.
/// - **The new pair is stored before anything else uses it.**
/// - **A lost answer is replayed.** If the refresh fails without an answer (or
///   with a server error), the same refresh token is sent again a little
///   later, inside the 30 seconds in which the server returns the same new
///   pair. After that the tokens are kept and the error goes to the caller.
/// - **Only a `401` of the refresh clears the tokens.** Any other failure keeps
///   them, so a bad connection never signs anyone out.
class AuthInterceptor extends Interceptor {
  new({
    required this._dio,
    required this._tokens,
    required this._refresh,
    required this._needsAuth,
    this._onSessionEnded,
    this._clock = const SystemClock(),
    this._pause = _realPause,
    this.replayDelays = defaultReplayDelays,
    this.replayWindow = defaultReplayWindow,
  });

  /// The error code of an access token that has run out: the only one that
  /// starts a refresh.
  static const tokenExpiredCode = 'token_expired';

  /// How long to wait before each new try of a refresh that got no answer.
  static const defaultReplayDelays = [
    Duration(seconds: 1),
    Duration(seconds: 3),
    Duration(seconds: 8),
  ];

  /// The server returns the same new pair for the same refresh token for 30
  /// seconds; tries stop a little before that.
  static const defaultReplayWindow = Duration(seconds: 25);

  static const _retriedKey = 'auth_retried';

  final Dio _dio;
  final TokenStore _tokens;
  final RefreshSession _refresh;
  final bool Function(RequestOptions options) _needsAuth;
  final SessionEnded? _onSessionEnded;
  final Clock _clock;
  final Future<void> Function(Duration) _pause;
  final List<Duration> replayDelays;
  final Duration replayWindow;

  Future<SessionTokens>? _refreshing;

  static Future<void> _realPause(Duration duration) {
    return Future<void>.delayed(duration);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_needsAuth(options)) {
      final tokens = await _tokens.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 || !_needsAuth(request)) {
      return handler.next(err);
    }

    try {
      final failure = ApiFailure.from(err);
      if (!failure.hasCode(tokenExpiredCode)) {
        // The session is over (signed out, revoked, password changed, token
        // reuse, ...): nothing to renew.
        if (await _tokens.read() != null) await _endSession(failure.code);
        return handler.next(err);
      }
      // Sent again once; a second expiry would be a loop.
      if (request.extra[_retriedKey] == true) return handler.next(err);

      final current = await _tokens.read();
      if (current == null) return handler.next(err);

      final sent = _bearer(request);
      final tokens = sent == null || sent != current.accessToken
          // Another request already renewed the pair while this one was away.
          ? current
          : await _refreshOnce(current);

      request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      request.extra[_retriedKey] = true;
      handler.resolve(await _dio.fetch<dynamic>(request));
    } on DioException catch (error) {
      handler.next(error);
    } on Object catch (error) {
      // The secure storage failed, or the refresh answer broke the contract:
      // a failed request, but not a lost connection.
      handler.next(
        DioException(
          requestOptions: request,
          error: error is DataException ? error : const ServerException(),
        ),
      );
    }
  }

  Future<SessionTokens> _refreshOnce(SessionTokens stale) {
    final running = _refreshing;
    if (running != null) return running;

    final refresh = _runRefresh(stale);
    _refreshing = refresh;
    unawaited(
      refresh.then<void>(
        (_) => _refreshing = null,
        onError: (Object _) => _refreshing = null,
      ),
    );
    return refresh;
  }

  Future<SessionTokens> _runRefresh(SessionTokens stale) async {
    final started = _clock.now();
    var attempt = 0;
    while (true) {
      try {
        final fresh = await _refresh(stale.refreshToken);
        // Before anything else: the old refresh token no longer works.
        await _tokens.write(fresh);
        return fresh;
      } on DioException catch (error) {
        final failure = ApiFailure.from(error);
        if (failure.statusCode == 401) {
          await _endSession(failure.code);
          rethrow;
        }
        final noAnswer =
            !failure.reachedServer || (failure.statusCode ?? 0) >= 500;
        final delay = attempt < replayDelays.length
            ? replayDelays[attempt]
            : null;
        final elapsed = _clock.now().difference(started);
        if (!noAnswer || delay == null || elapsed + delay > replayWindow) {
          rethrow;
        }
        attempt++;
        await _pause(delay);
      }
    }
  }

  Future<void> _endSession(String? code) async {
    await _tokens.clear();
    _onSessionEnded?.call(code);
  }

  static String? _bearer(RequestOptions request) {
    final header = request.headers['Authorization'];
    if (header is String && header.startsWith('Bearer ')) {
      return header.substring('Bearer '.length);
    }
    return null;
  }
}
