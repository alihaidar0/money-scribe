import 'package:equatable/equatable.dart';

/// The two tokens of a signed-in session. The access token lives ten minutes
/// and goes with every request; the refresh token is single use and trades for
/// a new pair. Neither is ever logged or shown.
final class SessionTokens extends Equatable {
  const new({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  @override
  List<Object> get props => [accessToken, refreshToken];

  /// Never prints the tokens, so a log line or an error report cannot leak
  /// them.
  @override
  String toString() => 'SessionTokens(…)';
}
