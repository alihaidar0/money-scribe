import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/environment/api_config.dart';

void main() {
  ApiConfig? parse(String value, {bool cleartext = false}) {
    return ApiConfig.parse(value, allowCleartext: cleartext);
  }

  group('no server', () {
    test('an empty value means the build has none', () {
      expect(parse(''), isNull);
      expect(parse('   '), isNull);
    });

    test('this test build has none either', () {
      expect(ApiConfig.current, isNull);
    });
  });

  group('an address', () {
    test('is the host, with the scheme', () {
      expect(
        parse('https://api.example.com')!.baseUrl,
        'https://api.example.com',
      );
    });

    test('loses a trailing slash and spaces around it', () {
      expect(
        parse('  https://api.example.com/  ')!.baseUrl,
        'https://api.example.com',
      );
    });

    test('keeps a port', () {
      expect(
        parse('https://api.example.com:8443')!.baseUrl,
        'https://api.example.com:8443',
      );
    });
  });

  group('an address that cannot be used stops the app at start', () {
    test('plain HTTP is refused', () {
      expect(() => parse('http://api.example.com'), throwsFormatException);
    });

    test('a path is refused, because the client already adds /api/v1', () {
      expect(
        () => parse('https://api.example.com/api/v1/'),
        throwsFormatException,
      );
    });

    test('a query, a fragment and a login are refused', () {
      expect(() => parse('https://api.example.com?x=1'), throwsFormatException);
      expect(() => parse('https://api.example.com#top'), throwsFormatException);
      expect(
        () => parse('https://user:secret@api.example.com'),
        throwsFormatException,
      );
    });

    test('something that is not an address is refused', () {
      expect(() => parse('api.example.com'), throwsFormatException);
      expect(() => parse('https://'), throwsFormatException);
    });

    test('the message never repeats the value', () {
      const secret = 'https://user:topsecret@api.example.com';

      try {
        parse(secret);
        fail('should have thrown');
      } on FormatException catch (error) {
        expect(error.message, isNot(contains('topsecret')));
        expect(error.message, isNot(contains(secret)));
      }
    });
  });

  group('plain HTTP for a backend on the developer machine', () {
    test(
      'is accepted for localhost and the emulator alias in a debug build',
      () {
        expect(
          parse('http://10.0.2.2:8000', cleartext: true)!.baseUrl,
          'http://10.0.2.2:8000',
        );
        expect(
          parse('http://localhost:8000', cleartext: true)!.baseUrl,
          'http://localhost:8000',
        );
      },
    );

    test('is refused for any other host, even in a debug build', () {
      expect(
        () => parse('http://api.example.com', cleartext: true),
        throwsFormatException,
      );
    });

    test('is refused when cleartext is not allowed', () {
      expect(() => parse('http://localhost:8000'), throwsFormatException);
    });
  });
}
