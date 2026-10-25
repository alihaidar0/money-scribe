import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/presentation/account_screen.dart';
import 'package:money_scribe/features/auth/presentation/change_password_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/open_screen.dart';

Finder get _switch =>
    find.widgetWithText(SwitchListTile, 'Sign in with fingerprint');

Finder get _dialog => find.byType(AlertDialog);

/// Opens the Settings, optionally turns the fingerprint sign-in on there, and
/// goes to Account and Change password.
Future<DemoController> _openChangePassword(
  WidgetTester tester, {
  bool fingerprintOn = true,
  AppLanguage language = AppLanguage.english,
}) async {
  final arabic = language == AppLanguage.arabic;
  final demo = await openSettings(tester, language: language);
  if (fingerprintOn) {
    final row = find.widgetWithText(
      SwitchListTile,
      arabic ? 'تسجيل الدخول بالبصمة' : 'Sign in with fingerprint',
    );
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(of: _dialog, matching: find.byType(TextField)),
      'secret',
    );
    await tester.pump();
    await tester.tap(
      find.widgetWithText(FilledButton, arabic ? 'متابعة' : 'Continue'),
    );
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Alex'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(arabic ? 'تغيير كلمة المرور' : 'Change password'));
  await tester.pumpAndSettle();
  return demo;
}

Future<void> _savePassword(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'old-password');
  await tester.enterText(fields.at(1), 'new-password-1');
  await tester.enterText(fields.at(2), 'new-password-1');
  await tester.pumpAndSettle();
  await tester.tap(find.byType(FilledButton).last);
  await tester.pumpAndSettle();
}

/// Goes back to the Settings and says whether the fingerprint switch is on.
Future<bool> _switchIsOnInSettings(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
  await tester.ensureVisible(_switch);
  return tester.widget<SwitchListTile>(_switch).value;
}

void main() {
  testWidgets('asks to turn it back on when it was on', (tester) async {
    await _openChangePassword(tester);

    await _savePassword(tester);

    expect(find.text('Turn fingerprint sign-in back on?'), findsOneWidget);
    expect(
      find.text(
        'Changing your password turned fingerprint sign-in off on all your '
        'phones. Turn it on again for this phone? You will touch the sensor '
        'to confirm.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Not now'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Turn on'), findsOneWidget);
    // The password is saved: it is said while the question is asked.
    expect(find.text('Password changed'), findsOneWidget);
  });

  testWidgets('Turn on makes the key again with the new password', (
    tester,
  ) async {
    await _openChangePassword(tester);
    await _savePassword(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Turn on'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.text('Fingerprint sign-in is on.'), findsOneWidget);
    expect(await _switchIsOnInSettings(tester), isTrue);
  });

  testWidgets('Not now leaves it off', (tester) async {
    await _openChangePassword(tester);
    await _savePassword(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Not now'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.text('Password changed'), findsOneWidget);
    expect(await _switchIsOnInSettings(tester), isFalse);
  });

  testWidgets('says so when the fingerprint did not match, and goes back', (
    tester,
  ) async {
    final demo = await _openChangePassword(tester);
    await _savePassword(tester);
    demo.update(const DemoSettings(fingerprint: DemoFingerprint.notMatched));

    await tester.tap(find.widgetWithText(FilledButton, 'Turn on'));
    await tester.pumpAndSettle();

    expect(
      find.text('Fingerprint not recognised. It was not turned on.'),
      findsOneWidget,
    );
    expect(find.byType(AccountScreen), findsOneWidget);
    expect(await _switchIsOnInSettings(tester), isFalse);
  });

  testWidgets('asks nothing when it was off', (tester) async {
    await _openChangePassword(tester, fingerprintOn: false);

    await _savePassword(tester);

    expect(_dialog, findsNothing);
    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.text('Password changed'), findsOneWidget);
  });

  testWidgets('asks nothing when the password was not changed', (tester) async {
    final demo = await _openChangePassword(tester);
    demo.update(
      const DemoSettings(passwordChange: DemoPasswordChange.passwordRefused),
    );

    await _savePassword(tester);

    expect(_dialog, findsNothing);
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    // Nothing was removed: still on, on the way back to the Settings.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(await _switchIsOnInSettings(tester), isTrue);
  });

  testWidgets('is in Arabic', (tester) async {
    await _openChangePassword(tester, language: AppLanguage.arabic);

    await _savePassword(tester);

    expect(find.text('تشغيل تسجيل الدخول بالبصمة مجددًا؟'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'ليس الآن'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'تشغيل'), findsOneWidget);
  });
}
