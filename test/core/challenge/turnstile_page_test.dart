import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/challenge/turnstile_page.dart';

void main() {
  group('TurnstileMessage.parse', () {
    test('reads a token', () {
      final message = TurnstileMessage.parse('{"event":"token","value":"abc"}');

      expect(message, isA<TurnstileToken>());
      expect((message! as TurnstileToken).token, 'abc');
    });

    test('reads an error', () {
      expect(
        TurnstileMessage.parse('{"event":"error"}'),
        isA<TurnstileError>(),
      );
    });

    test('a token that is empty, too long or not text is an error', () {
      for (final value in ['""', 'null', '12', '"${'a' * 2049}"']) {
        expect(
          TurnstileMessage.parse('{"event":"token","value":$value}'),
          isA<TurnstileError>(),
          reason: value,
        );
      }
    });

    test('ignores what is not a message of the page', () {
      for (final raw in ['', 'text', '[]', '{}', '{"event":"other"}', '12']) {
        expect(TurnstileMessage.parse(raw), isNull, reason: raw);
      }
    });

    test('the token never shows in the text of the message', () {
      expect(
        const TurnstileToken('secret').toString(),
        isNot(contains('secret')),
      );
    });
  });

  group('TurnstilePage.html', () {
    String page({bool dark = false, String language = 'en'}) =>
        TurnstilePage.html(
          siteKey: '0x4AAAAAAA-test',
          action: 'sign_in',
          language: language,
          dark: dark,
        );

    test('renders the widget with the key, the action and the language', () {
      final html = page(language: 'ar');

      expect(html, contains('"siteKey":"0x4AAAAAAA-test"'));
      expect(html, contains('"action":"sign_in"'));
      expect(html, contains('"language":"ar"'));
      expect(html, contains('"theme":"light"'));
      expect(html, contains('ChallengeChannel.postMessage'));
      expect(
        html,
        contains('https://challenges.cloudflare.com/turnstile/v0/api.js'),
      );
    });

    test('follows the theme', () {
      expect(page(dark: true), contains('"theme":"dark"'));
    });

    test('never lets a value close the script', () {
      final html = TurnstilePage.html(
        siteKey: '</script><b>',
        action: 'sign_in',
        language: 'en',
        dark: false,
      );

      expect(html, isNot(contains('</script><b>')));
    });
  });

  group('TurnstilePage.allowsNavigation', () {
    final page = Uri.parse('https://api.example.com');

    bool allows(String url, {required bool mainFrame}) =>
        TurnstilePage.allowsNavigation(
          Uri.parse(url),
          isMainFrame: mainFrame,
          page: page,
        );

    test('the main frame stays on the page', () {
      expect(allows('https://api.example.com', mainFrame: true), isTrue);
      expect(allows('https://api.example.com/', mainFrame: true), isTrue);
      expect(allows('about:blank', mainFrame: true), isTrue);
    });

    test('the main frame never leaves it', () {
      expect(allows('https://api.example.com/admin', mainFrame: true), isFalse);
      expect(allows('https://api.example.com/?x=1', mainFrame: true), isFalse);
      expect(allows('https://evil.example.org', mainFrame: true), isFalse);
      expect(allows('http://api.example.com', mainFrame: true), isFalse);
      expect(allows('https://api.example.com:8443', mainFrame: true), isFalse);
      expect(allows('intent://x#Intent;end', mainFrame: true), isFalse);
    });

    test('a frame may open secure addresses only', () {
      expect(
        allows('https://challenges.cloudflare.com/cdn-cgi/x', mainFrame: false),
        isTrue,
      );
      expect(
        allows('http://challenges.cloudflare.com', mainFrame: false),
        isFalse,
      );
      expect(allows('javascript:alert(1)', mainFrame: false), isFalse);
      expect(allows('file:///etc/passwd', mainFrame: false), isFalse);
    });
  });
}
