import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/presentation/account_screen.dart';
import 'package:money_scribe/features/auth/presentation/change_email_code_screen.dart';
import 'package:money_scribe/features/auth/presentation/change_email_screen.dart';

import '../../../support/build_app.dart';
import '../../../support/fake_ticker.dart';
import '../../../support/open_screen.dart';

late FakeTicker ticker;

/// The Account screen of a signed-in person, with a ticker the test moves.
Future<DemoController> openAccount(WidgetTester tester) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = tallPhone;
  addTearDown(tester.view.reset);
  ticker = FakeTicker();
  final demo = DemoController(latency: Duration.zero);
  await tester.pumpWidget(
    buildApp(
      demo: demo,
      ticker: ticker,
      authRepository: FakeAuthRepository(demo: demo, signedIn: true),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Alex'));
  await tester.pumpAndSettle();
  return demo;
}

Future<void> openForm(WidgetTester tester) async {
  await tester.tap(find.text('Change email'));
  await tester.pumpAndSettle();
}

Future<void> fillForm(
  WidgetTester tester, {
  String email = 'new@example.com',
  String password = 'secret',
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  await tester.pumpAndSettle();
}

Finder sendCode() => find.widgetWithText(FilledButton, 'Send code');

Future<void> send(WidgetTester tester) async {
  await tester.tap(sendCode());
  await tester.pumpAndSettle();
}

void main() {
  group('the form (ST-12)', () {
    testWidgets('has the two fields, and Send code waits for both', (
      tester,
    ) async {
      await openAccount(tester);

      await openForm(tester);

      expect(find.byType(ChangeEmailScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Change email'), findsOneWidget);
      expect(find.text('New email'), findsOneWidget);
      expect(find.text('Current password'), findsOneWidget);
      expect(tester.widget<FilledButton>(sendCode()).onPressed, isNull);

      await fillForm(tester);
      expect(tester.widget<FilledButton>(sendCode()).onPressed, isNotNull);
    });

    testWidgets('a wrong password is told under its field', (tester) async {
      final demo = await openAccount(tester);
      await openForm(tester);
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
      await fillForm(tester);

      await send(tester);

      expect(find.text('Your current password is incorrect.'), findsOneWidget);
      expect(find.byType(ChangeEmailScreen), findsOneWidget);
    });

    testWidgets('an address the server refuses is told under its field', (
      tester,
    ) async {
      await openAccount(tester);
      await openForm(tester);

      await fillForm(tester, email: FakeAuthRepository.demoTakenEmail);
      await send(tester);
      expect(
        find.text('Another account already uses this email address.'),
        findsOneWidget,
      );

      await fillForm(tester, email: 'alex@example.com');
      await send(tester);
      expect(find.text('This is already your email address.'), findsOneWidget);

      await fillForm(tester, email: 'not an address');
      await send(tester);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
    });

    testWidgets('a lock after wrong passwords counts down on the button', (
      tester,
    ) async {
      final demo = await openAccount(tester);
      await openForm(tester);
      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.locked),
      );
      await fillForm(tester);

      await send(tester);

      final button = find.widgetWithText(FilledButton, 'Try again in 15:00');
      expect(button, findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
    });

    testWidgets('a busy server asks to try again shortly', (tester) async {
      final demo = await openAccount(tester);
      await openForm(tester);
      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.unavailable),
      );
      await fillForm(tester);

      await send(tester);

      expect(find.text('The service is busy'), findsOneWidget);
    });
  });

  group('the code (ST-12b)', () {
    Future<void> reachCodeScreen(WidgetTester tester) async {
      await openForm(tester);
      await fillForm(tester);
      await send(tester);
    }

    Future<void> typeCode(WidgetTester tester, String code) async {
      await tester.enterText(find.byType(TextField), code);
      await tester.pumpAndSettle();
    }

    testWidgets('Send code opens the code screen for the new address', (
      tester,
    ) async {
      await openAccount(tester);

      await reachCodeScreen(tester);

      expect(find.byType(ChangeEmailCodeScreen), findsOneWidget);
      expect(find.text('Confirm your new email'), findsOneWidget);
      expect(find.textContaining('We sent a 6-digit code to'), findsOneWidget);
      expect(find.textContaining('new@example.com'), findsOneWidget);
      expect(find.text('Resend code in 1:00'), findsOneWidget);
      expect(find.text('Use another address'), findsOneWidget);
      expect(find.text('Cancel email change'), findsOneWidget);
    });

    testWidgets('a correct code shows the new address on the Account', (
      tester,
    ) async {
      await openAccount(tester);
      await reachCodeScreen(tester);

      await typeCode(tester, '123456');

      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.text('new@example.com'), findsOneWidget);
      expect(find.text('alex@example.com'), findsNothing);
      expect(find.text('Email changed'), findsOneWidget);
    });

    testWidgets('a wrong code is told with the tries left', (tester) async {
      final demo = await openAccount(tester);
      await reachCodeScreen(tester);
      demo.update(const DemoSettings(code: DemoCode.wrong));

      await typeCode(tester, '000000');

      expect(find.textContaining('incorrect'), findsOneWidget);
      expect(find.byType(ChangeEmailCodeScreen), findsOneWidget);
    });

    testWidgets('Use another address goes back to the form', (tester) async {
      await openAccount(tester);
      await reachCodeScreen(tester);

      await tester.tap(find.text('Use another address'));
      await tester.pumpAndSettle();

      expect(find.byType(ChangeEmailScreen), findsOneWidget);
      // The password is not kept: it is asked for again.
      expect(tester.widget<FilledButton>(sendCode()).onPressed, isNull);
    });

    testWidgets('Cancel drops the change and leaves the address as it was', (
      tester,
    ) async {
      await openAccount(tester);
      await reachCodeScreen(tester);

      await tester.tap(find.text('Cancel email change'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.text('alex@example.com'), findsOneWidget);
      expect(find.text('Email changed'), findsNothing);
    });

    testWidgets('a cancel that cannot reach the server is told', (
      tester,
    ) async {
      final demo = await openAccount(tester);
      await reachCodeScreen(tester);
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));

      await tester.tap(find.text('Cancel email change'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Couldn't cancel the change. Check your connection and try again.",
        ),
        findsOneWidget,
      );
      expect(find.byType(ChangeEmailCodeScreen), findsOneWidget);
    });

    testWidgets('a new code asks for the password again', (tester) async {
      await openAccount(tester);
      await reachCodeScreen(tester);
      ticker.tick(0);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resend code'));
      await tester.pumpAndSettle();
      expect(find.text('Send a new code'), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'secret',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Send code'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Resend code in 1:00'), findsOneWidget);
    });

    testWidgets('a wrong password for a new code is told', (tester) async {
      final demo = await openAccount(tester);
      await reachCodeScreen(tester);
      ticker.tick(0);
      await tester.pumpAndSettle();
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));

      await tester.tap(find.text('Resend code'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'nope',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Send code'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your current password is incorrect.'), findsOneWidget);
    });

    testWidgets('Cancel in the password prompt sends nothing', (tester) async {
      await openAccount(tester);
      await reachCodeScreen(tester);
      ticker.tick(0);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Resend code'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancel'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Resend code'), findsOneWidget);
    });
  });
}
