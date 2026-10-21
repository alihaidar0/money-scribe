import 'package:flutter/foundation.dart' show kDebugMode;

/// Where the server is, as the build says. The address is a build-time value
/// (`--dart-define-from-file=.env.<environment>`, see `docs/backend-api.md`),
/// never written in the source. A build without one has no server: the app
/// keeps its fake repositories.
final class ApiConfig {
  const new _(this.baseUrl);

  /// Hosts that may be reached without TLS, in a debug build only: the
  /// machine itself and the Android emulator's alias for the host.
  static const cleartextHosts = {'localhost', '127.0.0.1', '10.0.2.2'};

  static const _define = String.fromEnvironment('API_BASE_URL');

  /// The server of this build, or `null` when the build has none.
  static final ApiConfig? current = parse(_define, allowCleartext: kDebugMode);

  /// The address without a path or a trailing slash, such as
  /// `https://api.example.com`. Every request path starts at its root
  /// (`/api/v1/...`).
  final String baseUrl;

  /// Reads the build-time address. An empty value means "no server" and gives
  /// `null`. A value that cannot be used throws a [FormatException] at start,
  /// so a mistake in a build is found at once and never silently falls back to
  /// fake data. The message never repeats the value.
  ///
  /// The address must be HTTPS. With [allowCleartext], plain HTTP is accepted
  /// for [cleartextHosts] too, for a backend running on the developer's
  /// machine.
  static ApiConfig? parse(String value, {required bool allowCleartext}) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException(
        'API_BASE_URL is not an address such as https://api.example.com.',
      );
    }
    final secure = uri.scheme == 'https';
    final localCleartext =
        allowCleartext &&
        uri.scheme == 'http' &&
        cleartextHosts.contains(uri.host);
    if (!secure && !localCleartext) {
      throw const FormatException('API_BASE_URL must use https.');
    }
    final hasPath = uri.path.isNotEmpty && uri.path != '/';
    if (hasPath || uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) {
      throw const FormatException(
        'API_BASE_URL must be the address of the server only: no path, '
        'query or login. The paths of the API start with /api/v1.',
      );
    }

    final port = uri.hasPort ? ':${uri.port}' : '';
    return ApiConfig._('${uri.scheme}://${uri.host}$port');
  }
}
