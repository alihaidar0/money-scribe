import 'package:dio/dio.dart';
import 'package:money_scribe/core/environment/api_config.dart';
import 'package:money_scribe/core/network/auth_interceptor.dart';
import 'package:money_scribe/core/network/token_store.dart';

/// The time a request may take. The free staging server sleeps after 15
/// minutes without a request and the first call afterwards can take about a
/// minute, so the waits are long.
abstract final class ApiTimeouts {
  static const connect = Duration(seconds: 90);
  static const send = Duration(seconds: 30);
  static const receive = Duration(seconds: 90);
}

/// A Dio for the server, with no interceptors. It talks JSON only. It is the
/// Dio of the calls that need no token (register, sign in, the code calls) and
/// of the refresh itself.
///
/// Nothing is logged: requests and answers hold personal and financial data,
/// so no logging interceptor is ever added.
Dio createPlainDio(ApiConfig config) {
  return Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: ApiTimeouts.connect,
      sendTimeout: ApiTimeouts.send,
      receiveTimeout: ApiTimeouts.receive,
      contentType: Headers.jsonContentType,
      headers: {Headers.acceptHeader: Headers.jsonContentType},
    ),
  );
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
}) {
  final dio = createPlainDio(config);
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
