import 'dart:convert';

import 'package:money_scribe/core/network/session_tokens.dart';
import 'package:money_scribe/core/storage/secure_value_store.dart';

/// Where the session tokens are kept between runs of the app.
abstract interface class TokenStore {
  /// The tokens of the session, or `null` when nobody is signed in.
  Future<SessionTokens?> read();

  /// Replaces the tokens. Called with the new pair before anything else uses
  /// it, because the old refresh token no longer works.
  Future<void> write(SessionTokens tokens);

  Future<void> clear();
}

/// Keeps the tokens in the secure storage, as one value so the two never get
/// out of step.
class SecureTokenStore implements TokenStore {
  const new(this._store);

  static const _key = 'session_tokens';

  final SecureValueStore _store;

  @override
  Future<SessionTokens?> read() async {
    final text = await _store.read(_key);
    if (text == null) return null;
    try {
      final json = jsonDecode(text);
      if (json is Map<String, dynamic>) {
        final access = json['access'];
        final refresh = json['refresh'];
        if (access is String &&
            access.isNotEmpty &&
            refresh is String &&
            refresh.isNotEmpty) {
          return SessionTokens(accessToken: access, refreshToken: refresh);
        }
      }
    } on FormatException {
      // Fall through: a damaged value is no session.
    }
    await _store.delete(_key);
    return null;
  }

  @override
  Future<void> write(SessionTokens tokens) {
    return _store.write(
      _key,
      jsonEncode({
        'access': tokens.accessToken,
        'refresh': tokens.refreshToken,
      }),
    );
  }

  @override
  Future<void> clear() => _store.delete(_key);
}
