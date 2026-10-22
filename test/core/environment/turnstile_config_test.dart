import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/environment/turnstile_config.dart';

void main() {
  group('TurnstileConfig.parse', () {
    test('an empty value means no key', () {
      expect(TurnstileConfig.parse(''), isNull);
      expect(TurnstileConfig.parse('   '), isNull);
    });

    test('reads a site key', () {
      expect(
        TurnstileConfig.parse(' 0x4AAAAAAA-test_key ')?.siteKey,
        '0x4AAAAAAA-test_key',
      );
    });

    test('refuses anything that is not a site key, without repeating it', () {
      for (final value in ['a b', 'key"x', '<script>', 'a' * 65, 'key!']) {
        expect(
          () => TurnstileConfig.parse(value),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              isNot(contains(value)),
            ),
          ),
          reason: value,
        );
      }
    });
  });
}
