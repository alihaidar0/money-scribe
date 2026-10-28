import 'package:dio/dio.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/time/clock.dart';

/// What the server said in its latest failed answer, for the screens that show
/// a failure: the reference of the request (`X-Request-ID`) to quote to
/// support, and the wait of a `429`.
///
/// The Blocs report a failure as a status, not as the answer, so the answer is
/// kept here once, by [LastFailureInterceptor], and the failure view reads it.
/// The latest failed answer replaces the one before, so an old reference is
/// never shown for a new problem; one older than [referenceAge] is not shown
/// either. The reference holds no personal data.
class LastFailure {
  new({this._clock = const SystemClock()});

  /// How long a reference stays worth showing.
  static const referenceAge = Duration(minutes: 5);

  final Clock _clock;

  String? _requestId;
  Duration? _retryAfter;
  DateTime? _at;

  /// Remembers [failure], replacing the one before. A failure the server did
  /// not answer (no connection) leaves nothing to show.
  void record(ApiFailure failure) {
    _at = _clock.now();
    _requestId = failure.reachedServer ? failure.requestId : null;
    _retryAfter = failure.statusCode == 429
        ? failure.retryAfter ?? ApiFailure.missingRetryAfter
        : null;
  }

  /// The reference of the latest failed request, or `null`.
  String? get requestId {
    final at = _at;
    if (at == null || _clock.now().difference(at) > referenceAge) return null;
    return _requestId;
  }

  /// How long the server still asks the app to wait after its latest `429`, or
  /// `null` when the latest failure was not one or the wait is over.
  Duration? get wait {
    final at = _at;
    final retryAfter = _retryAfter;
    if (at == null || retryAfter == null) return null;
    final left = retryAfter - _clock.now().difference(at);
    return left > Duration.zero ? left : null;
  }
}

/// Remembers every failed answer in a [LastFailure]. A `401` is left out: the
/// session handling answers it (a new token, or signing in again), and it is
/// not a problem to show.
class LastFailureInterceptor extends Interceptor {
  const new(this._failure);

  final LastFailure _failure;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode != 401) {
      _failure.record(ApiFailure.from(err));
    }
    handler.next(err);
  }
}
