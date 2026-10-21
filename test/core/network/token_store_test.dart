import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/network/session_tokens.dart';
import 'package:money_scribe/core/network/token_store.dart';

import '../../support/in_memory_secure_value_store.dart';

void main() {
  late InMemorySecureValueStore secure;
  late SecureTokenStore store;

  const tokens = SessionTokens(
    accessToken: 'access-token-value',
    refreshToken: 'refresh-token-value',
  );

  setUp(() {
    secure = InMemorySecureValueStore();
    store = SecureTokenStore(secure);
  });

  test('has no session at first', () async {
    expect(await store.read(), isNull);
  });

  test('keeps the pair it was given', () async {
    await store.write(tokens);

    expect(await store.read(), tokens);
  });

  test('replaces the pair, never mixing the old and the new', () async {
    await store.write(tokens);
    const next = SessionTokens(accessToken: 'a2', refreshToken: 'r2');

    await store.write(next);

    expect(await store.read(), next);
  });

  test(
    'writes both tokens in one value, so they cannot get out of step',
    () async {
      await store.write(tokens);

      expect(secure.writes, hasLength(1));
      expect(secure.values, hasLength(1));
    },
  );

  test('forgets the session on clear', () async {
    await store.write(tokens);

    await store.clear();

    expect(await store.read(), isNull);
    expect(secure.values, isEmpty);
  });

  group('a value that is damaged', () {
    for (final entry in {
      'not JSON': 'not json at all',
      'JSON of another shape': '[1, 2]',
      'a token missing': '{"access": "a"}',
      'an empty token': '{"access": "", "refresh": "r"}',
      'a token that is not text': '{"access": 1, "refresh": "r"}',
    }.entries) {
      test('${entry.key} is no session, and is removed', () async {
        secure.values['session_tokens'] = entry.value;

        expect(await store.read(), isNull);
        expect(secure.values, isEmpty);
      });
    }
  });

  test('never prints the tokens', () {
    expect(tokens.toString(), isNot(contains('access-token-value')));
    expect(tokens.toString(), isNot(contains('refresh-token-value')));
  });
}
