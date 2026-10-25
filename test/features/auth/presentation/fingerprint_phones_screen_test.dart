import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/presentation/fingerprint_phones_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/open_screen.dart';

Finder get _switch =>
    find.widgetWithText(SwitchListTile, 'Sign in with fingerprint');

Finder get _phonesRow =>
    find.widgetWithText(ListTile, 'Phones with fingerprint sign-in');

Finder get _arabicSwitch =>
    find.widgetWithText(SwitchListTile, 'تسجيل الدخول بالبصمة');

Finder get _arabicPhonesRow =>
    find.widgetWithText(ListTile, 'هواتف الدخول بالبصمة');

Finder _remove(String name) => find.byTooltip('Remove $name');

Finder get _confirmRemove => find.widgetWithText(FilledButton, 'Remove');

/// Turns the fingerprint sign-in on in the Settings, as a person does.
/// Scrolls to [finder], which a long list at a large text size builds only
/// when it is near.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
}

Future<DemoController> _openSettingsWithFingerprint(
  WidgetTester tester, {
  AppLanguage language = AppLanguage.english,
}) async {
  final arabic = language == AppLanguage.arabic;
  final demo = await openSettings(tester, language: language);
  final row = arabic ? _arabicSwitch : _switch;
  await _reveal(tester, row);
  await tester.tap(row);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    ),
    'secret',
  );
  await tester.pump();
  await tester.tap(
    find.widgetWithText(FilledButton, arabic ? 'متابعة' : 'Continue'),
  );
  await tester.pumpAndSettle();
  return demo;
}

Future<DemoController> _openPhones(
  WidgetTester tester, {
  AppLanguage language = AppLanguage.english,
}) async {
  final demo = await _openSettingsWithFingerprint(tester, language: language);
  final row = language == AppLanguage.arabic ? _arabicPhonesRow : _phonesRow;
  await _reveal(tester, row);
  await tester.tap(row);
  await tester.pumpAndSettle();
  return demo;
}

Future<void> _removePhone(WidgetTester tester, String name) async {
  await tester.tap(_remove(name));
  await tester.pumpAndSettle();
  await tester.tap(_confirmRemove);
  await tester.pumpAndSettle();
}

void main() {
  group('the row of the Settings', () {
    testWidgets('is not there while the sign-in is off', (tester) async {
      await openSettings(tester);

      expect(_switch, findsOneWidget);
      expect(_phonesRow, findsNothing);
    });

    testWidgets('shows up once the sign-in is on, and opens the list', (
      tester,
    ) async {
      await _openSettingsWithFingerprint(tester);

      expect(_phonesRow, findsOneWidget);
      expect(
        find.text('See which phones can sign in, and remove one.'),
        findsOneWidget,
      );

      await tester.ensureVisible(_phonesRow);
      await tester.tap(_phonesRow);
      await tester.pumpAndSettle();

      expect(find.byType(FingerprintPhonesScreen), findsOneWidget);
    });
  });

  group('the list', () {
    testWidgets('shows the phones, with this one marked', (tester) async {
      await _openPhones(tester);

      expect(
        find.widgetWithText(AppBar, 'Phones with fingerprint sign-in'),
        findsOneWidget,
      );
      expect(
        find.text(
          'These phones can sign in to your account with a fingerprint. '
          'Remove one you no longer use.',
        ),
        findsOneWidget,
      );
      expect(find.text('This phone'), findsOneWidget);
      expect(find.text('Pixel 8'), findsOneWidget);
      expect(find.text('Galaxy S24'), findsOneWidget);
      expect(find.text('iPhone 15'), findsOneWidget);
      // Only the Galaxy has signed the account in.
      expect(find.textContaining('Last used'), findsOneWidget);
      expect(find.text('Not used to sign in yet'), findsNWidgets(2));
      expect(find.textContaining('Stops working on'), findsNWidgets(3));
    });

    testWidgets('asks before removing a phone', (tester) async {
      await _openPhones(tester);

      await tester.tap(_remove('Galaxy S24'));
      await tester.pumpAndSettle();

      expect(find.text('Remove Galaxy S24?'), findsOneWidget);
      expect(
        find.text('That phone will need your password to sign in again.'),
        findsOneWidget,
      );
      expect(find.text('Galaxy S24'), findsOneWidget);
    });

    testWidgets('Cancel removes nothing', (tester) async {
      await _openPhones(tester);
      await tester.tap(_remove('Galaxy S24'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Galaxy S24'), findsOneWidget);
      expect(find.text('Phone removed.'), findsNothing);
    });

    testWidgets('Remove takes the phone off the list and says so', (
      tester,
    ) async {
      await _openPhones(tester);

      await _removePhone(tester, 'Galaxy S24');

      expect(find.text('Galaxy S24'), findsNothing);
      expect(find.text('iPhone 15'), findsOneWidget);
      expect(find.text('Phone removed.'), findsOneWidget);
    });

    testWidgets('removing this phone turns the sign-in off here', (
      tester,
    ) async {
      await _openPhones(tester);
      await tester.tap(_remove('Pixel 8'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Fingerprint sign-in will be turned off on this phone. You can turn '
          'it on again in Settings.',
        ),
        findsOneWidget,
      );
      await tester.tap(_confirmRemove);
      await tester.pumpAndSettle();

      expect(find.text('This phone'), findsNothing);
      expect(find.text('Galaxy S24'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(_switch).value, isFalse);
      expect(_phonesRow, findsNothing);
    });

    testWidgets('a removal that failed offers Retry, which removes', (
      tester,
    ) async {
      final demo = await _openPhones(tester);
      demo.update(const DemoSettings(save: DemoSave.fails));

      await tester.tap(_remove('Galaxy S24'));
      await tester.pumpAndSettle();
      await tester.tap(_confirmRemove);
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Couldn't change fingerprint sign-in. Check your connection.",
        ),
        findsOneWidget,
      );
      expect(find.text('Galaxy S24'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Galaxy S24'), findsNothing);
      expect(find.text('Phone removed.'), findsOneWidget);
    });

    testWidgets('with every phone removed it says so and goes back', (
      tester,
    ) async {
      await _openPhones(tester);

      await _removePhone(tester, 'Galaxy S24');
      await _removePhone(tester, 'iPhone 15');
      await _removePhone(tester, 'Pixel 8');

      expect(find.text('No phones yet'), findsOneWidget);
      expect(
        find.text('Turn on fingerprint sign-in in Settings to add this phone.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Back to settings'));
      await tester.pumpAndSettle();

      expect(find.byType(FingerprintPhonesScreen), findsNothing);
      expect(_switch, findsOneWidget);
    });

    testWidgets('no connection offers Try again, which loads', (tester) async {
      final demo = await _openSettingsWithFingerprint(tester);
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await tester.ensureVisible(_phonesRow);
      await tester.tap(_phonesRow);
      await tester.pumpAndSettle();

      expect(find.text('No connection'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Galaxy S24'), findsOneWidget);
    });

    testWidgets('a server failure offers Try again', (tester) async {
      final demo = await _openSettingsWithFingerprint(tester);
      demo.update(const DemoSettings(scenario: DemoScenario.error));
      await tester.ensureVisible(_phonesRow);
      await tester.tap(_phonesRow);
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('fits at 200% text size', (tester) async {
      await _openPhones(tester);

      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(FingerprintPhonesScreen), findsOneWidget);
      expect(find.text('Galaxy S24'), findsOneWidget);
    });

    testWidgets('is in Arabic, with Western digits', (tester) async {
      await _openPhones(tester, language: AppLanguage.arabic);

      expect(
        find.widgetWithText(AppBar, 'هواتف الدخول بالبصمة'),
        findsOneWidget,
      );
      expect(find.text('هذا الهاتف'), findsOneWidget);
      expect(find.byTooltip('إزالة Galaxy S24'), findsOneWidget);
      expect(find.textContaining(RegExp('[٠-٩]')), findsNothing);
    });
  });
}
