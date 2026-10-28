import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/app/shell/floating_navigation_bar.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/presentation/account_screen.dart';
import 'package:money_scribe/features/auth/presentation/change_password_screen.dart';
import 'package:money_scribe/features/auth/presentation/forgot_password_screen.dart';
import 'package:money_scribe/features/auth/presentation/welcome_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/open_screen.dart';

Finder inDialog(Finder finder) =>
    find.descendant(of: find.byType(AlertDialog), matching: finder);

Finder deleteButton() =>
    inDialog(find.widgetWithText(FilledButton, 'Delete account'));

Future<DemoController> openAccount(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
}) async {
  final demo = await openSettings(
    tester,
    settings: settings,
    language: language,
  );
  await tester.tap(find.text('Alex'));
  await tester.pumpAndSettle();
  return demo;
}

Future<void> openChangePassword(WidgetTester tester) async {
  await tester.tap(find.text('Change password'));
  await tester.pumpAndSettle();
}

Future<void> fillPasswords(
  WidgetTester tester, {
  String current = 'old-password',
  String next = 'new-password-1',
  String confirmation = 'new-password-1',
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), current);
  await tester.enterText(fields.at(1), next);
  await tester.enterText(fields.at(2), confirmation);
  await tester.pumpAndSettle();
}

Finder savePassword() => find.widgetWithText(FilledButton, 'Save password');

void main() {
  group('the account (ST-2)', () {
    testWidgets('shows the initial, the name, the email and the rows', (
      tester,
    ) async {
      await openAccount(tester);

      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Account'), findsOneWidget);
      expect(find.byType(FloatingNavigationBar), findsNothing);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('alex@example.com'), findsOneWidget);
      expect(find.text('Change password'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);
      expect(find.byIcon(LucideIcons.logOutDir), findsOneWidget);
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
    });

    testWidgets('Delete account is in the error colour', (tester) async {
      await openAccount(tester);

      final text = tester.widget<Text>(find.text('Delete account'));
      final context = tester.element(find.byType(AccountScreen));

      expect(text.style?.color, Theme.of(context).colorScheme.error);
    });

    testWidgets('back returns to the Settings', (tester) async {
      await openAccount(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Preferences'), findsOneWidget);
    });

    testWidgets('the Settings row offers a retry when it cannot load', (
      tester,
    ) async {
      final demo = await openSettings(tester);
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load your account"), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.tap(find.byIcon(LucideIcons.refreshCw));
      await tester.pumpAndSettle();

      expect(find.text('Alex'), findsOneWidget);
    });
  });

  group('signing out (ST-10)', () {
    testWidgets('asks first, and Cancel keeps the person signed in', (
      tester,
    ) async {
      await openAccount(tester);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Sign out?'), findsOneWidget);
      expect(
        find.text('You will need to sign in again to see your data.'),
        findsOneWidget,
      );

      await tester.tap(inDialog(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(AccountScreen), findsOneWidget);
    });

    testWidgets('Sign out leads to the Welcome screen', (tester) async {
      await openAccount(tester);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      await tester.tap(inDialog(find.text('Sign out')));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(AccountScreen), findsNothing);
    });
  });

  group('editing the name (ST-2)', () {
    Finder nameField() => inDialog(find.byType(TextField));
    Finder saveButton() => inDialog(find.widgetWithText(FilledButton, 'Save'));

    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.text('Edit name'));
      await tester.pumpAndSettle();
    }

    testWidgets('opens with the current name, and Save waits for a change', (
      tester,
    ) async {
      await openAccount(tester);

      await openDialog(tester);

      expect(find.text('Edit your name'), findsOneWidget);
      expect(tester.widget<TextField>(nameField()).controller?.text, 'Alex');
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);

      await tester.enterText(nameField(), 'Dana');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
    });

    testWidgets('Cancel closes it and changes nothing', (tester) async {
      await openAccount(tester);
      await openDialog(tester);
      await tester.enterText(nameField(), 'Dana');

      await tester.tap(inDialog(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Alex'), findsOneWidget);
    });

    testWidgets('Save shows the new name, with a message', (tester) async {
      await openAccount(tester);
      await openDialog(tester);
      await tester.enterText(nameField(), 'Dana');
      await tester.pumpAndSettle();

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Dana'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      expect(find.text('Name updated'), findsOneWidget);
    });

    testWidgets('the field stops at 100 characters', (tester) async {
      await openAccount(tester);
      await openDialog(tester);

      await tester.enterText(nameField(), 'x' * 150);
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(nameField()).controller?.text.length,
        100,
      );
    });

    testWidgets('no connection is told, and what was typed stays', (
      tester,
    ) async {
      final demo = await openAccount(tester);
      await openDialog(tester);
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await tester.enterText(nameField(), 'Dana');
      await tester.pumpAndSettle();

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Couldn't save your name. Check your connection and try again.",
        ),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(nameField()).controller?.text, 'Dana');
    });

    testWidgets('the Settings row shows the new name when coming back', (
      tester,
    ) async {
      await openAccount(tester);
      await openDialog(tester);
      await tester.enterText(nameField(), 'Dana');
      await tester.pumpAndSettle();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Dana'), findsOneWidget);
      expect(find.text('Alex'), findsNothing);
    });
  });

  group('deleting the account (ST-11)', () {
    testWidgets('asks for the password, and Cancel closes the dialog', (
      tester,
    ) async {
      await openAccount(tester);

      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();

      expect(find.text('Delete your account?'), findsOneWidget);
      expect(
        find.text(
          'All your data will be permanently deleted from the server. This '
          'cannot be undone.',
        ),
        findsOneWidget,
      );
      expect(inDialog(find.byType(TextField)), findsOneWidget);
      expect(tester.widget<FilledButton>(deleteButton()).onPressed, isNull);

      await tester.tap(inDialog(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(AccountScreen), findsOneWidget);
    });

    testWidgets('a wrong password is told in the dialog', (tester) async {
      final demo = await openAccount(tester);
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();

      await tester.enterText(inDialog(find.byType(TextField)), 'nope');
      await tester.pumpAndSettle();
      await tester.tap(deleteButton());
      await tester.pumpAndSettle();

      expect(find.text('The password is incorrect.'), findsOneWidget);
      expect(find.byType(AccountScreen), findsOneWidget);
    });

    testWidgets('a lock after wrong passwords counts down on the button', (
      tester,
    ) async {
      final demo = await openAccount(tester);
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.locked),
      );

      await tester.enterText(inDialog(find.byType(TextField)), 'secret');
      await tester.pumpAndSettle();
      await tester.tap(deleteButton());
      await tester.pumpAndSettle();

      final button = inDialog(
        find.widgetWithText(FilledButton, 'Try again in 15:00'),
      );
      expect(button, findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('a busy server is told in the dialog', (tester) async {
      final demo = await openAccount(tester);
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.unavailable),
      );

      await tester.enterText(inDialog(find.byType(TextField)), 'secret');
      await tester.pumpAndSettle();
      await tester.tap(deleteButton());
      await tester.pumpAndSettle();

      expect(
        find.text('The service is busy. Please try again shortly.'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('no connection is told in the dialog', (tester) async {
      final demo = await openAccount(tester);
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));

      await tester.enterText(inDialog(find.byType(TextField)), 'secret');
      await tester.pumpAndSettle();
      await tester.tap(deleteButton());
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Couldn't delete your account. Check your connection and try again.",
        ),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('the right password deletes the account and signs out', (
      tester,
    ) async {
      await openAccount(tester);
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();

      await tester.enterText(inDialog(find.byType(TextField)), 'secret');
      await tester.pumpAndSettle();
      await tester.tap(deleteButton());
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('changing the password (ST-6)', () {
    testWidgets('has the three fields and the buttons, and no password rule', (
      tester,
    ) async {
      await openAccount(tester);
      await openChangePassword(tester);

      expect(find.byType(ChangePasswordScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Change password'), findsOneWidget);
      expect(find.text('Current password'), findsOneWidget);
      expect(find.text('New password'), findsOneWidget);
      expect(find.text('Confirm new password'), findsOneWidget);
      // The server owns the password policy: no hint about length or content.
      expect(find.textContaining('characters'), findsNothing);
      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(savePassword(), findsOneWidget);
      expect(tester.widget<FilledButton>(savePassword()).onPressed, isNull);
    });

    testWidgets('a confirmation that differs is told', (tester) async {
      await openAccount(tester);
      await openChangePassword(tester);

      await fillPasswords(tester, confirmation: 'something else');

      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(tester.widget<FilledButton>(savePassword()).onPressed, isNull);
    });

    testWidgets('Save password goes back with a message', (tester) async {
      await openAccount(tester);
      await openChangePassword(tester);
      await fillPasswords(tester);

      await tester.tap(savePassword());
      await tester.pumpAndSettle();

      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.text('Password changed'), findsOneWidget);
    });

    testWidgets('a wrong current password is told under its field', (
      tester,
    ) async {
      final demo = await openAccount(tester);
      await openChangePassword(tester);
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
      await fillPasswords(tester);

      await tester.tap(savePassword());
      await tester.pumpAndSettle();

      expect(find.text('Your current password is incorrect.'), findsOneWidget);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('a refused new password is explained under its field', (
      tester,
    ) async {
      final demo = await openAccount(tester);
      await openChangePassword(tester);
      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.passwordRefused),
      );
      await fillPasswords(tester);

      await tester.tap(savePassword());
      await tester.pumpAndSettle();

      expect(
        find.text('Your password is too short. Use at least 15 characters.'),
        findsOneWidget,
      );
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('the same password as the current one is told', (tester) async {
      await openAccount(tester);
      await openChangePassword(tester);
      await fillPasswords(
        tester,
        current: 'same-password-1',
        next: 'same-password-1',
        confirmation: 'same-password-1',
      );

      await tester.tap(savePassword());
      await tester.pumpAndSettle();

      expect(
        find.text('The new password must be different from your current one.'),
        findsOneWidget,
      );
    });

    testWidgets('a lock after wrong passwords counts down on the button', (
      tester,
    ) async {
      final demo = await openAccount(tester);
      await openChangePassword(tester);
      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.locked),
      );
      await fillPasswords(tester);

      await tester.tap(savePassword());
      await tester.pumpAndSettle();

      final button = find.widgetWithText(FilledButton, 'Try again in 15:00');
      expect(button, findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
    });

    testWidgets('a busy server asks to try again shortly', (tester) async {
      final demo = await openAccount(tester);
      await openChangePassword(tester);
      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.unavailable),
      );
      await fillPasswords(tester);

      await tester.tap(savePassword());
      await tester.pumpAndSettle();

      expect(find.text('The service is busy'), findsOneWidget);
    });

    testWidgets('no connection keeps what was typed, and Try again saves', (
      tester,
    ) async {
      final demo = await openAccount(tester);
      await openChangePassword(tester);
      await fillPasswords(tester);
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));

      await tester.tap(savePassword());
      await tester.pumpAndSettle();
      expect(find.text('No connection'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountScreen), findsOneWidget);
    });

    testWidgets('Forgot your password? starts the reset flow', (tester) async {
      await openAccount(tester);
      await openChangePassword(tester);

      await tester.tap(find.text('Forgot your password?'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });
  });

  testWidgets('the account is in Arabic', (tester) async {
    await openSettings(tester, language: AppLanguage.arabic);
    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'الحساب'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
    expect(find.text('حذف الحساب'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
