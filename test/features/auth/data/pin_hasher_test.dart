import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/auth/data/pin_hasher.dart';

void main() {
  // Few rounds, so the tests are quick; the scheme is the same.
  const hasher = PinHasher(iterations: 20, useIsolate: false);

  group('PBKDF2-HMAC-SHA256', () {
    test('gives the published test vector (RFC 7914, one round)', () {
      // PBKDF2-HMAC-SHA256 of "passwd" and "salt", one round, 32 bytes.
      final key = PinHasher.pbkdf2(
        utf8.encode('passwd'),
        utf8.encode('salt'),
        1,
      );

      expect(
        key.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
        '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc',
      );
    });

    test('gives the published test vector (RFC 7914, 80000 rounds)', () {
      final key = PinHasher.pbkdf2(
        utf8.encode('Password'),
        utf8.encode('NaCl'),
        80000,
      );

      expect(
        key.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
        '4ddcd8f60b98be21830cee5ef22701f9641a4418d04c0414aeff08876b34ab56',
      );
    });
  });

  group('a PIN and its verifier', () {
    test('the right PIN matches, a wrong one does not', () async {
      final verifier = await hasher.create('1234');

      expect(await hasher.matches('1234', verifier), isTrue);
      expect(await hasher.matches('1235', verifier), isFalse);
      expect(await hasher.matches('', verifier), isFalse);
    });

    test('the PIN is not in what is kept', () async {
      final verifier = await hasher.create('4821');

      expect(verifier.toJson(), isNot(contains('4821')));
      expect(verifier.hash, isNot(contains('4821')));
    });

    test('every verifier has its own salt, so the same PIN differs', () async {
      final first = await hasher.create('1234');
      final second = await hasher.create('1234');

      expect(first.salt, isNot(second.salt));
      expect(first.hash, isNot(second.hash));
    });

    test('keeps the number of rounds it was made with', () async {
      final verifier = await const PinHasher(
        iterations: 7,
        useIsolate: false,
      ).create('1234');

      // A change of the default later must not break a PIN already saved.
      expect(verifier.iterations, 7);
      expect(await hasher.matches('1234', verifier), isTrue);
    });

    test('works in an isolate too', () async {
      const inIsolate = PinHasher(iterations: 20);
      final verifier = await inIsolate.create('0007');

      expect(await inIsolate.matches('0007', verifier), isTrue);
      expect(await inIsolate.matches('0008', verifier), isFalse);
    });
  });

  group('what is kept', () {
    test('is read back as it was written', () async {
      final verifier = await hasher.create('1234');

      final read = PinVerifier.tryParse(verifier.toJson());

      expect(read?.salt, verifier.salt);
      expect(read?.hash, verifier.hash);
      expect(read?.iterations, verifier.iterations);
    });

    test('anything else is not a verifier', () {
      for (final text in [
        null,
        '',
        'not json',
        '[]',
        '{"v":2,"salt":"a","hash":"b","iter":1}',
        '{"v":1,"salt":1,"hash":"b","iter":1}',
        '{"v":1,"salt":"a","hash":"b"}',
      ]) {
        expect(PinVerifier.tryParse(text), isNull, reason: '$text');
      }
    });

    test('a verifier that cannot be decoded matches nothing', () async {
      const broken = PinVerifier(salt: '%%%', hash: '%%%', iterations: 20);

      expect(await hasher.matches('1234', broken), isFalse);
    });
  });
}
