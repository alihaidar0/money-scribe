import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/open_screen.dart';

Finder get _row =>
    find.widgetWithText(SwitchListTile, 'Sign in with fingerprint');

Finder get _dialog => find.byType(AlertDialog);

Future<void> _turnOn(WidgetTester tester, {String password = 'secret'}) async {
  await tester.ensureVisible(_row);
  await tester.tap(_row);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(of: _dialog, matching: find.byType(TextField)),
    password,
  );
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
  await tester.pumpAndSettle();
}

bool _isOn(WidgetTester tester) => tester.widget<SwitchListTile>(_row).value;

void main() {
  testWidgets('is off, with a hint that the PIN is never a way in', (
    tester,
  ) async {
    await openSettings(tester);

    expect(_row, findsOneWidget);
    expect(_isOn(tester), isFalse);
    expect(
      find.text(
        'Sign in with your fingerprint instead of your password. '
        'Your PIN is never a way to sign in.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('asks for the password, then turns on', (tester) async {
    await openSettings(tester);
    await tester.ensureVisible(_row);

    await tester.tap(_row);
    await tester.pumpAndSettle();

    expect(find.text('Turn on fingerprint sign-in'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    // Nothing is turned on until the password is typed and sent.
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), 'secret');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Fingerprint sign-in is on.'), findsOneWidget);
    expect(_isOn(tester), isTrue);
  });

  testWidgets('cancelling the password dialog changes nothing', (tester) async {
    await openSettings(tester);
    await tester.ensureVisible(_row);

    await tester.tap(_row);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(_isOn(tester), isFalse);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('turns off again', (tester) async {
    await openSettings(tester);
    await _turnOn(tester);

    await tester.ensureVisible(_row);
    await tester.tap(_row);
    await tester.pumpAndSettle();

    expect(find.text('Fingerprint sign-in is off.'), findsOneWidget);
    expect(_isOn(tester), isFalse);
  });

  group('when it does not turn on', () {
    testWidgets('a wrong password says so', (tester) async {
      await openSettings(
        tester,
        settings: const DemoSettings(signIn: DemoSignIn.wrongPassword),
      );

      await _turnOn(tester);

      expect(
        find.text(
          "That password isn't right. Fingerprint sign-in was not turned on.",
        ),
        findsOneWidget,
      );
      expect(_isOn(tester), isFalse);
    });

    testWidgets('a fingerprint that does not match says so', (tester) async {
      await openSettings(
        tester,
        settings: const DemoSettings(fingerprint: DemoFingerprint.notMatched),
      );

      await _turnOn(tester);

      expect(
        find.text('Fingerprint not recognised. It was not turned on.'),
        findsOneWidget,
      );
      expect(_isOn(tester), isFalse);
    });

    testWidgets('a key the server refuses gives no reason', (tester) async {
      await openSettings(
        tester,
        settings: const DemoSettings(
          fingerprint: DemoFingerprint.attestationRefused,
        ),
      );

      await _turnOn(tester);

      expect(
        find.text(
          "This phone can't be used for fingerprint sign-in. "
          'Use your password to sign in.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a lost connection says so', (tester) async {
      await openSettings(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.noConnection),
      );

      await _turnOn(tester);

      expect(
        find.text(
          "Couldn't change fingerprint sign-in. Check your connection.",
        ),
        findsOneWidget,
      );
    });
  });

  group('on a phone that cannot', () {
    testWidgets('with no fingerprint enrolled, says to add one', (
      tester,
    ) async {
      await openSettings(
        tester,
        settings: const DemoSettings(fingerprint: DemoFingerprint.notEnrolled),
      );

      expect(tester.widget<SwitchListTile>(_row).onChanged, isNull);
      expect(
        find.descendant(
          of: _row,
          matching: find.text(
            "Set up a fingerprint in your phone's settings first.",
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('with no secure hardware, says so', (tester) async {
      await openSettings(
        tester,
        settings: const DemoSettings(fingerprint: DemoFingerprint.unsupported),
      );

      expect(tester.widget<SwitchListTile>(_row).onChanged, isNull);
      expect(
        find.text("This phone can't keep a sign-in key. Use your password."),
        findsOneWidget,
      );
    });
  });

  testWidgets('in Arabic it is worded in Arabic', (tester) async {
    await openSettings(tester, language: AppLanguage.arabic);

    final row = find.widgetWithText(SwitchListTile, 'تسجيل الدخول بالبصمة');
    expect(row, findsOneWidget);
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.text('تشغيل تسجيل الدخول بالبصمة'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'متابعة'), findsOneWidget);
  });
}
