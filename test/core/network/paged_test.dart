import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/paged.dart';

void main() {
  group('readAllPages', () {
    test('a single page is the whole list', () async {
      final items = await readAllPages<int>((next) async {
        expect(next, isNull);
        return const Paged(items: [1, 2]);
      });

      expect(items, [1, 2]);
    });

    test('follows what each page gives as the next one, in order', () async {
      final asked = <String?>[];
      final pages = {
        null: const Paged(items: [1, 2], next: 'b'),
        'b': const Paged(items: [3], next: 'c'),
        'c': const Paged(items: [4, 5]),
      };

      final items = await readAllPages<int>((next) async {
        asked.add(next);
        return pages[next]!;
      });

      expect(items, [1, 2, 3, 4, 5]);
      expect(asked, [null, 'b', 'c']);
    });

    test('an empty page in the middle does not stop it', () async {
      final pages = {
        null: const Paged(items: [1], next: 'b'),
        'b': const Paged<int>(items: [], next: 'c'),
        'c': const Paged(items: [2]),
      };

      expect(await readAllPages<int>((next) async => pages[next]!), [1, 2]);
    });

    test('a server that gives the same page again is a failure', () async {
      await expectLater(
        readAllPages<int>(
          (next) async => const Paged(items: [1], next: 'same'),
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('a list that never ends is a failure, after the limit', () async {
      var calls = 0;

      await expectLater(
        readAllPages<int>(
          (next) async => Paged(items: [calls], next: 'page-${calls++}'),
          maxPages: 5,
        ),
        throwsA(isA<ServerException>()),
      );
      expect(calls, 5);
    });

    test('a failed page fails the whole read', () async {
      await expectLater(
        readAllPages<int>((next) async {
          if (next == null) return const Paged(items: [1], next: 'b');
          throw const NoConnectionException();
        }),
        throwsA(isA<NoConnectionException>()),
      );
    });
  });

  group('cursorOfNextPage', () {
    const base = 'https://api.example.test';

    test('no next page has no cursor', () {
      expect(cursorOfNextPage(null, baseUrl: base), isNull);
    });

    test('reads the cursor of an address on the API origin', () {
      expect(
        cursorOfNextPage(
          'https://api.example.test/api/v1/x/?cursor=abc&limit=50',
          baseUrl: base,
        ),
        'abc',
      );
    });

    test('refuses an address on another host, scheme or port', () {
      for (final next in [
        'https://evil.example.test/api/v1/x/?cursor=abc',
        'http://api.example.test/api/v1/x/?cursor=abc',
        'https://api.example.test:8443/api/v1/x/?cursor=abc',
        'https://api.example.test.evil.test/api/v1/x/?cursor=abc',
        '/api/v1/x/?cursor=abc',
        '//evil.example.test/api/v1/x/?cursor=abc',
      ]) {
        expect(
          () => cursorOfNextPage(next, baseUrl: base),
          throwsA(isA<ServerException>()),
          reason: next,
        );
      }
    });

    test('refuses an address with no cursor', () {
      expect(
        () => cursorOfNextPage(
          'https://api.example.test/api/v1/x/',
          baseUrl: base,
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
