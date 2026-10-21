import 'package:dio/dio.dart';
import 'package:money_scribe/core/api/export.dart';
import 'package:money_scribe/core/device/device_info.dart';
import 'package:money_scribe/core/device/time_zone_source.dart';
import 'package:money_scribe/core/environment/api_config.dart';
import 'package:money_scribe/core/network/dio_factory.dart';
import 'package:money_scribe/core/network/slow_request_monitor.dart';
import 'package:money_scribe/core/network/token_store.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/features/auth/data/remote/remote_auth_repository.dart';

/// The paths of the calls that carry no access token: the ones that start or
/// end a session, or ask for a code. Every other path of the API does.
const authPublicPaths = {
  '/api/v1/auth/register/',
  '/api/v1/auth/verify-email/',
  '/api/v1/auth/resend-code/',
  '/api/v1/auth/sign-in/',
  '/api/v1/auth/refresh/',
  '/api/v1/auth/sign-out/',
};

/// The real authentication, built from the pieces it needs: the account
/// repository, and the HTTP client that keeps the session alive for the
/// features that follow.
final class RemoteAuth {
  const new _({required this.repository, required this.dio});

  /// Wires the repository and the client to each other: the client renews the
  /// session through the repository, and the repository hears when the server
  /// ended it. A [monitor] watches every request. [httpAdapter] replaces the
  /// network, for tests.
  factory create({
    required ApiConfig config,
    required TokenStore tokens,
    required DeviceInfoSource device,
    required TimeZoneSource timeZone,
    required String Function() language,
    Clock clock = const SystemClock(),
    SlowRequestMonitor? monitor,
    HttpClientAdapter? httpAdapter,
  }) {
    final plain = createPlainDio(config, monitor: monitor);
    late final RemoteAuthRepository repository;
    final dio = createAuthenticatedDio(
      config: config,
      tokens: tokens,
      refresh: (refreshToken) => repository.refreshSession(refreshToken),
      needsAuth: (options) => !authPublicPaths.contains(options.path),
      onSessionEnded: (code) => repository.sessionEnded(code),
      monitor: monitor,
    );
    if (httpAdapter != null) {
      final adapter = monitor == null
          ? httpAdapter
          : MonitoredHttpAdapter(httpAdapter, monitor);
      plain.httpClientAdapter = adapter;
      dio.httpClientAdapter = adapter;
    }
    repository = RemoteAuthRepository(
      plain: AuthClient(plain),
      authenticated: AuthClient(dio),
      tokens: tokens,
      device: device,
      timeZone: timeZone,
      language: language,
      clock: clock,
    );
    return RemoteAuth._(repository: repository, dio: dio);
  }

  /// The account on the server.
  final RemoteAuthRepository repository;

  /// The Dio of the whole app: it sends the access token and renews it. A
  /// feature builds its generated client on it.
  final Dio dio;
}
