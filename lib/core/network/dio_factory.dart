import 'package:dio/dio.dart';
import 'package:money_scribe/core/environment/api_config.dart';
import 'package:money_scribe/core/network/auth_interceptor.dart';
import 'package:money_scribe/core/network/date_only_interceptor.dart';
import 'package:money_scribe/core/network/last_failure.dart';
import 'package:money_scribe/core/network/omit_nulls_interceptor.dart';
import 'package:money_scribe/core/network/slow_request_monitor.dart';
import 'package:money_scribe/core/network/token_store.dart';

/// The time a request may take. The free staging server sleeps after 15
/// minutes without a request and the first call afterwards can take about a
/// minute, so the waits are long.
abstract final class ApiTimeouts {
  static const connect = Duration(seconds: 90);
  static const send = Duration(seconds: 30);
  static const receive = Duration(seconds: 90);
}

/// A Dio for the server, with no session handling. It talks JSON only,
/// leaves out any field that is `null` (see [OmitNullsInterceptor]) and sends
/// a day as `YYYY-MM-DD` (see [DateOnlyInterceptor]). It is the
/// Dio of the calls that need no token (register, sign in, the code calls) and
/// of the refresh itself.
///
/// With a [monitor], every request that goes out is watched, so the app can
/// tell the person when the server is slow to answer. With a [lastFailure],
/// every failed answer is noted for the failure screens (see
/// [LastFailureInterceptor]).
///
/// Nothing is logged: requests and answers hold personal and financial data,
/// so no logging interceptor is ever added.
Dio createPlainDio(
  ApiConfig config, {
  SlowRequestMonitor? monitor,
  LastFailure? lastFailure,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: ApiTimeouts.connect,
      sendTimeout: ApiTimeouts.send,
      receiveTimeout: ApiTimeouts.receive,
      contentType: Headers.jsonContentType,
      headers: {Headers.acceptHeader: Headers.jsonContentType},
    ),
  );
  dio.interceptors.addAll(const [
    OmitNullsInterceptor(),
    DateOnlyInterceptor(),
  ]);
  if (lastFailure != null) {
    dio.interceptors.add(LastFailureInterceptor(lastFailure));
  }
  if (monitor != null) {
    dio.httpClientAdapter = MonitoredHttpAdapter(
      dio.httpClientAdapter,
      monitor,
    );
  }
  return dio;
}

/// A Dio that sends the access token and keeps the session alive (see
/// [AuthInterceptor]). [needsAuth] says which requests carry the token: the
/// feature that owns the paths decides.
Dio createAuthenticatedDio({
  required ApiConfig config,
  required TokenStore tokens,
  required RefreshSession refresh,
  required bool Function(RequestOptions options) needsAuth,
  SessionEnded? onSessionEnded,
  SlowRequestMonitor? monitor,
  LastFailure? lastFailure,
}) {
  final dio = createPlainDio(
    config,
    monitor: monitor,
    lastFailure: lastFailure,
  );
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokens: tokens,
      refresh: refresh,
      needsAuth: needsAuth,
      onSessionEnded: onSessionEnded,
    ),
  );
  return dio;
}
