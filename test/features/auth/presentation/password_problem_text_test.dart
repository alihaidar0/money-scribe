import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/auth/domain/password_problem.dart';
import 'package:money_scribe/features/auth/presentation/password_problem_text.dart';

void main() {
  late AppLocalizations english;
  late AppLocalizations arabic;

  setUpAll(() async {
    english = await AppLocalizations.delegate.load(const Locale('en'));
    arabic = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  String text(AppLocalizations l10n, PasswordProblem problem) {
    return passwordProblemText(l10n, problem);
  }

  group('the number comes from the server', () {
    test('a minimum length is told in both languages', () {
      const problem = PasswordProblem(PasswordIssue.tooShort, limit: 15);

      expect(
        text(english, problem),
        'Your password is too short. Use at least 15 characters.',
      );
      expect(text(arabic, problem), contains('15'));
    });

    test(
      'a different limit gives a different message, with no new release',
      () {
        const problem = PasswordProblem(PasswordIssue.tooShort, limit: 12);

        expect(text(english, problem), contains('12'));
        expect(text(english, problem), isNot(contains('15')));
      },
    );

    test('a maximum length is told in both languages', () {
      const problem = PasswordProblem(PasswordIssue.tooLong, limit: 128);

      expect(
        text(english, problem),
        'Your password is too long. Use at most 128 characters.',
      );
      expect(text(arabic, problem), contains('128'));
    });

    test('a limit the server did not give is left out of the message', () {
      expect(
        text(english, const PasswordProblem(PasswordIssue.tooShort)),
        'Your password is too short.',
      );
      expect(
        text(english, const PasswordProblem(PasswordIssue.tooLong)),
        'Your password is too long.',
      );
    });
  });

  group('every reason has its own words in English and Arabic', () {
    const reasons = [
      PasswordIssue.tooSimilar,
      PasswordIssue.tooCommon,
      PasswordIssue.compromised,
    ];

    for (final issue in reasons) {
      test('$issue', () {
        final problem = PasswordProblem(issue);

        expect(text(english, problem), isNotEmpty);
        expect(text(arabic, problem), isNotEmpty);
        expect(text(arabic, problem), isNot(text(english, problem)));
      });
    }

    test('the reasons differ from each other', () {
      final messages = {
        for (final issue in reasons) text(english, PasswordProblem(issue)),
      };

      expect(messages, hasLength(reasons.length));
    });
  });

  group('a reason the app does not know', () {
    test("shows the server's English text as it is, in any language", () {
      const problem = PasswordProblem(
        PasswordIssue.other,
        detail: 'This password was used before.',
      );

      expect(text(english, problem), 'This password was used before.');
      expect(text(arabic, problem), 'This password was used before.');
    });

    test('without any text shows a general refusal', () {
      const problem = PasswordProblem(PasswordIssue.other);

      expect(
        text(english, problem),
        'This password cannot be used. Choose a different one.',
      );
    });
  });
}
