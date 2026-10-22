import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/presentation/app_lock_screen.dart';
import 'package:money_scribe/features/auth/presentation/create_pin_screen.dart';
import 'package:money_scribe/features/auth/presentation/email_verified_screen.dart';
import 'package:money_scribe/features/auth/presentation/forgot_password_screen.dart';
import 'package:money_scribe/features/auth/presentation/new_password_screen.dart';
import 'package:money_scribe/features/auth/presentation/password_changed_screen.dart';
import 'package:money_scribe/features/auth/presentation/pin_entry_screen.dart';
import 'package:money_scribe/features/auth/presentation/register_screen.dart';
import 'package:money_scribe/features/auth/presentation/reset_code_screen.dart';
import 'package:money_scribe/features/auth/presentation/sign_in_screen.dart';
import 'package:money_scribe/features/auth/presentation/verify_email_screen.dart';
import 'package:money_scribe/features/auth/presentation/welcome_screen.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';
import 'package:money_scribe/features/settings/presentation/pay_setup_screen.dart';

import '../support/build_app.dart';
import '../support/fake_ticker.dart';

/// The link test: every button of the authentication flow leads where the
/// design says, with the fake data accepting anything.

late DemoController _demo;
late FakeTicker _ticker;
late FakeAuthRepository _auth;

/// The time the fake server sees. The ticker is fake, so a test moves this on
/// together with it when it waits for the server.
late DateTime _now;

Future<void> _pumpApp(WidgetTester tester, {bool signedIn = false}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(412, 915);
  addTearDown(tester.view.reset);
  _demo = DemoController(latency: Duration.zero);
  _ticker = FakeTicker();
  _now = DateTime(2026, 10, 11, 9);
  _auth = FakeAuthRepository(demo: _demo, now: () => _now, signedIn: signedIn);
  await tester.pumpWidget(
    buildApp(demo: _demo, ticker: _ticker, authRepository: _auth),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _tapButton(WidgetTester tester, Type type) async {
  await tester.tap(find.byType(type).first);
  await tester.pumpAndSettle();
}

Future<void> _typeInField(WidgetTester tester, int index, String text) async {
  await tester.enterText(find.byType(TextField).at(index), text);
  await tester.pumpAndSettle();
}

Future<void> _typeCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.pumpAndSettle();
}

Future<void> _go(WidgetTester tester, String path) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

void main() {
  group('Welcome', () {
    testWidgets('Sign in opens the sign-in form, and back returns', (
      tester,
    ) async {
      await _pumpApp(tester);

      await _tapText(tester, 'Sign in');
      expect(find.byType(SignInScreen), findsOneWidget);

      await _back(tester);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('Create account opens the registration form', (tester) async {
      await _pumpApp(tester);

      await _tapText(tester, 'Create account');

      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('has no back arrow and shows the Terms and Privacy links', (
      tester,
    ) async {
      await _pumpApp(tester);

      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.textContaining('Terms', findRichText: true), findsOneWidget);
      expect(
        find.textContaining('Privacy Policy', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('Sign in', () {
    testWidgets('any email and password lead to the Overview', (tester) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');

      await _typeInField(tester, 0, 'whoever@example.com');
      await _typeInField(tester, 1, 'x');
      await _tapButton(tester, FilledButton);

      expect(find.byType(OverviewScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      // An existing account has data.
      expect(find.text('Balance'), findsOneWidget);
    });

    testWidgets('the Overview cannot be left with the back button to sign in', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      await _tapButton(tester, FilledButton);

      expect(find.byType(SignInScreen), findsNothing);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('Forgot password opens the reset flow', (tester) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');

      await _tapText(tester, 'Forgot password?');

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('Create account swaps to the registration form', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');

      await _tapText(tester, 'Create account');

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
    });

    testWidgets('a wrong password is said under the password field', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      _demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));

      await _tapButton(tester, FilledButton);

      expect(find.text('Wrong password.'), findsOneWidget);
      expect(find.text('No account uses this email address.'), findsNothing);
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('an email without an account is said under the email field, '
        'and the message goes away when the email is edited', (tester) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      _demo.update(const DemoSettings(signIn: DemoSignIn.emailNotRegistered));

      await _tapButton(tester, FilledButton);

      expect(find.text('No account uses this email address.'), findsOneWidget);
      expect(find.text('Wrong password.'), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'other@b.c');
      await tester.pumpAndSettle();

      expect(find.text('No account uses this email address.'), findsNothing);
    });

    testWidgets('the wrong password message goes away when it is edited', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      _demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
      await _tapButton(tester, FilledButton);
      expect(find.text('Wrong password.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(1), 'another');
      await tester.pumpAndSettle();

      expect(find.text('Wrong password.'), findsNothing);
    });

    testWidgets('a bot challenge opens, and solving it signs in once', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      _demo.update(const DemoSettings(signIn: DemoSignIn.challengeRequired));

      await _tapButton(tester, FilledButton);

      expect(find.text('Security check'), findsOneWidget);
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(_auth.isSignedIn, isFalse);

      await _tapText(tester, 'I am not a robot (demo)');

      expect(find.byType(SignInScreen), findsNothing);
      expect(_auth.isSignedIn, isTrue);
    });

    testWidgets('closing the challenge sends nothing and keeps the form', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      _demo.update(const DemoSettings(signIn: DemoSignIn.challengeRequired));
      await _tapButton(tester, FilledButton);

      await _tapText(tester, 'Cancel');

      expect(find.text('Security check'), findsNothing);
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(_auth.isSignedIn, isFalse);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('a refused token opens a new challenge with a message', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      _demo.update(const DemoSettings(signIn: DemoSignIn.challengeRejected));
      await _tapButton(tester, FilledButton);
      await _tapText(tester, 'I am not a robot (demo)');

      expect(find.text('Security check'), findsOneWidget);
      expect(find.text('The check did not work. Try again.'), findsOneWidget);
      expect(_auth.isSignedIn, isFalse);
    });

    testWidgets('five wrong passwords lock sign-in with a countdown', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      _demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));

      for (var attempt = 0; attempt < 5; attempt++) {
        await _tapButton(tester, FilledButton);
      }

      expect(
        find.text('Too many attempts. Try again in 5:00.'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).first).enabled,
        isFalse,
      );
      // Forgot password stays available.
      await _tapText(tester, 'Forgot password?');
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);

      await _back(tester);
      _ticker.tick(299);
      await tester.pumpAndSettle();
      expect(
        find.text('Too many attempts. Try again in 4:59.'),
        findsOneWidget,
      );
    });

    testWidgets('an address that is not verified opens the code screen', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      await _typeInField(tester, 0, 'late@example.com');
      _demo.update(const DemoSettings(signIn: DemoSignIn.emailNotVerified));

      await _tapButton(tester, FilledButton);

      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      // The address keeps its left-to-right order inside the sentence.
      expect(find.textContaining('late@example.com'), findsOneWidget);
      expect(
        find.textContaining('is not verified yet'),
        findsOneWidget,
        reason: 'nothing was sent, and the screen says so',
      );
      // The hint is for someone who just created an account.
      expect(
        find.textContaining('You may already have an account'),
        findsNothing,
      );
      // No code is on its way: one can be asked for at once.
      expect(find.widgetWithText(TextButton, 'Resend code'), findsOneWidget);

      await _tapText(tester, 'Resend code');
      expect(find.text('Resend code in 1:00'), findsOneWidget);
    });

    testWidgets('a busy server asks to try again shortly', (tester) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      _demo.update(const DemoSettings(signIn: DemoSignIn.unavailable));

      await _tapButton(tester, FilledButton);

      expect(find.text('The service is busy'), findsOneWidget);
      expect(find.text('Please try again shortly.'), findsOneWidget);

      _demo.update(const DemoSettings());
      await _tapText(tester, 'Try again');

      expect(find.byType(OverviewScreen), findsOneWidget);
    });

    testWidgets('no connection shows the full-screen state; Try again works', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      _demo.update(const DemoSettings(scenario: DemoScenario.noConnection));

      await _tapButton(tester, FilledButton);
      expect(find.text('No connection'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);

      _demo.update(const DemoSettings());
      await _tapText(tester, 'Try again');

      expect(find.byType(OverviewScreen), findsOneWidget);
    });

    testWidgets('a server failure shows Something went wrong', (tester) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      _demo.update(const DemoSettings(scenario: DemoScenario.error));

      await _tapButton(tester, FilledButton);

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('the form keeps what was typed behind the failure view', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      await _typeInField(tester, 0, 'me@example.com');
      _demo.update(const DemoSettings(scenario: DemoScenario.error));
      await _tapButton(tester, FilledButton);
      expect(find.text('Something went wrong'), findsOneWidget);

      _demo.update(const DemoSettings());
      await _tapText(tester, 'Try again');

      expect(find.byType(OverviewScreen), findsOneWidget);
    });
  });

  group('Create account', () {
    Future<void> fillAndSubmit(WidgetTester tester) async {
      await _typeInField(tester, 0, 'Alex');
      await _typeInField(tester, 1, 'alex@example.com');
      await _typeInField(tester, 2, 'an invented passphrase');
      await _typeInField(tester, 3, 'an invented passphrase');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await _tapButton(tester, FilledButton);
    }

    testWidgets('the button waits for the agreement and a password', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Create account');
      bool enabled() =>
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed !=
          null;

      expect(enabled(), isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(enabled(), isFalse, reason: 'agreed, but no password yet');

      // Any password is enough for the button: the server judges it.
      await _typeInField(tester, 2, 'x');
      expect(enabled(), isTrue);
    });

    testWidgets('the form gives no hint about what a password must be', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Create account');

      expect(find.textContaining('characters'), findsNothing);
      expect(find.textContaining('number'), findsNothing);
    });

    testWidgets('any data lead to the code screen, then through the setup', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Create account');

      await fillAndSubmit(tester);
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
      expect(
        find.textContaining('alex@example.com'),
        findsOneWidget,
        reason: 'the code screen says where the code went',
      );

      await _typeCode(tester, '481729');
      expect(find.byType(EmailVerifiedScreen), findsOneWidget);
      expect(find.text('Your account is ready.'), findsOneWidget);

      await _tapText(tester, 'Continue');
      expect(find.byType(PaySetupScreen), findsOneWidget);

      await _tapText(tester, 'Continue');
      expect(find.byType(OverviewScreen), findsOneWidget);
      // A new account has no data: the first-launch Overview.
      expect(find.text('Welcome to Money Scribe'), findsOneWidget);
    });

    testWidgets('two payments chosen in the setup show the parts', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Create account');
      await fillAndSubmit(tester);
      await _typeCode(tester, '481729');
      await _tapText(tester, 'Continue');
      await _tapText(tester, 'Two payments a month');
      await _tapText(tester, 'Continue');
      expect(find.text('Welcome to Money Scribe'), findsOneWidget);

      _demo.update(_demo.settings.copyWith(scenario: DemoScenario.normal));
      await tester.pumpAndSettle();

      expect(find.text('Part 1'), findsOneWidget);
      expect(find.text('Part 2 · 16th–end'), findsOneWidget);
    });

    testWidgets('the setup offers two payments with pay days', (tester) async {
      await _pumpApp(tester, signedIn: true);
      await _go(tester, AppRoutes.paySetup);
      expect(find.text('First payment is paid on day'), findsNothing);

      await _tapText(tester, 'Two payments a month');

      expect(find.text('First payment is paid on day'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      await tester.tap(find.byTooltip('Increase').first);
      await tester.pumpAndSettle();
      expect(find.text('21'), findsOneWidget);

      await _tapText(tester, 'One payment a month');
      expect(find.text('First payment is paid on day'), findsNothing);
    });

    testWidgets('data the server refuses show its reasons, worded by the app', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Create account');
      _demo.update(const DemoSettings(registration: DemoRegistration.rejected));

      await fillAndSubmit(tester);

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      // The number in the message comes from the server.
      expect(
        find.text('Your password is too short. Use at least 15 characters.'),
        findsOneWidget,
      );
      expect(find.text('Passwords do not match.'), findsNothing);
    });

    testWidgets('two different passwords are refused on the device', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Create account');
      await _typeInField(tester, 0, 'Alex');
      await _typeInField(tester, 1, 'alex@example.com');
      await _typeInField(tester, 2, 'one passphrase');
      await _typeInField(tester, 3, 'another passphrase');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await _tapButton(tester, FilledButton);

      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(_demo.settings.scenario, isNot(DemoScenario.empty));
    });

    testWidgets('a second registration inside the wait counts down on the '
        'button', (tester) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Create account');
      _demo.update(const DemoSettings(registration: DemoRegistration.tooSoon));

      await fillAndSubmit(tester);

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('Try again in 1:00'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      _ticker.tick(41);
      await tester.pumpAndSettle();
      expect(find.text('Try again in 0:41'), findsOneWidget);

      _ticker.tick(0);
      await tester.pumpAndSettle();
      expect(find.text('Try again in 0:00'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('a busy server asks to try again shortly', (tester) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Create account');
      _demo.update(
        const DemoSettings(registration: DemoRegistration.unavailable),
      );

      await fillAndSubmit(tester);

      expect(find.text('The service is busy'), findsOneWidget);
      expect(find.text('Please try again shortly.'), findsOneWidget);
    });

    testWidgets('Sign in at the bottom swaps to the sign-in form', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Create account');

      await _tapText(tester, 'Sign in');

      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });

  group('Verify your email', () {
    // The person arrives from Create account: a code was sent, and the server
    // asks to wait a minute before another.
    Future<void> openAfterRegistering(WidgetTester tester) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Create account');
      await _typeInField(tester, 0, 'Alex');
      await _typeInField(tester, 1, 'alex@example.com');
      await _typeInField(tester, 2, 'an invented passphrase');
      await _typeInField(tester, 3, 'an invented passphrase');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await _tapButton(tester, FilledButton);
      expect(find.byType(VerifyEmailScreen), findsOneWidget);
    }

    // Opened with no code asked for yet.
    Future<void> openCodeScreen(WidgetTester tester) async {
      await _pumpApp(tester);
      await _go(tester, AppRoutes.verifyEmail);
    }

    testWidgets('waits for six digits before Verify can be pressed', (
      tester,
    ) async {
      await openAfterRegistering(tester);
      bool enabled() =>
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed !=
          null;

      expect(enabled(), isFalse);
      await _typeCode(tester, '48172');
      expect(enabled(), isFalse);
      expect(find.text('Resend code in 1:00'), findsOneWidget);
      expect(find.textContaining('6-digit code'), findsOneWidget);
    });

    testWidgets('the hint for someone who already has an account', (
      tester,
    ) async {
      await openAfterRegistering(tester);

      expect(
        find.textContaining(
          'No code? You may already have an account: sign in or reset your '
          'password.',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('the hint links lead to sign in and to resetting the '
        'password', (tester) async {
      await openAfterRegistering(tester);
      await tester.tapOnText(find.textRange.ofSubstring('reset your password'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);

      await _back(tester);
      await tester.tapOnText(find.textRange.ofSubstring('sign in'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('a wrong code shows the tries left, then the code is dead', (
      tester,
    ) async {
      await openAfterRegistering(tester);
      _demo.update(const DemoSettings(code: DemoCode.wrong));

      await _typeCode(tester, '481729');
      expect(
        find.text('The code is incorrect. 4 attempts left.'),
        findsOneWidget,
      );

      await _typeCode(tester, '48172');
      expect(find.textContaining('incorrect'), findsNothing);

      for (final entry in {
        '481730': 'The code is incorrect. 3 attempts left.',
        '481731': 'The code is incorrect. 2 attempts left.',
        '481732': 'The code is incorrect. 1 attempt left.',
      }.entries) {
        await _typeCode(tester, entry.key);
        expect(find.text(entry.value), findsOneWidget);
        await _typeCode(tester, '48173');
      }

      await _typeCode(tester, '481733');
      expect(
        find.text('Too many incorrect codes. This code no longer works.'),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      // A new code can be asked for only when the server allows it.
      expect(find.text('Resend code in 1:00'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Resend code'), findsNothing);

      // The minute passes for the server and for the countdown.
      _now = _now.add(const Duration(seconds: 60));
      _ticker.tick(0);
      await tester.pumpAndSettle();
      _demo.update(const DemoSettings());
      await _tapText(tester, 'Resend code');

      expect(
        find.text('Too many incorrect codes. This code no longer works.'),
        findsNothing,
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    });

    testWidgets('too many tries kills the code at once', (tester) async {
      await openAfterRegistering(tester);
      _demo.update(const DemoSettings(code: DemoCode.attemptsExceeded));

      await _typeCode(tester, '481729');

      expect(
        find.text('Too many incorrect codes. This code no longer works.'),
        findsOneWidget,
      );
      expect(find.text('Resend code in 1:00'), findsOneWidget);
    });

    testWidgets('an expired code can be replaced', (tester) async {
      await openCodeScreen(tester);
      _demo.update(const DemoSettings(code: DemoCode.expired));
      await _typeCode(tester, '481729');

      expect(find.text('This code has expired.'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
        isNotNull,
        reason: 'the tonal Resend code button',
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

      _demo.update(const DemoSettings());
      await _tapText(tester, 'Resend code');

      expect(find.text('This code has expired.'), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    });

    testWidgets('an expired code still waits for the server to send another', (
      tester,
    ) async {
      await openAfterRegistering(tester);
      _demo.update(const DemoSettings(code: DemoCode.expired));
      await _typeCode(tester, '481729');

      expect(find.text('This code has expired.'), findsOneWidget);
      expect(find.text('Resend code in 1:00'), findsOneWidget);
    });

    testWidgets('counts down to Resend code', (tester) async {
      await openAfterRegistering(tester);

      _ticker.tick(42);
      await tester.pumpAndSettle();
      expect(find.text('Resend code in 0:42'), findsOneWidget);

      _now = _now.add(const Duration(seconds: 60));
      _ticker.tick(0);
      await tester.pumpAndSettle();
      expect(find.text('Resend code in 0:00'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Resend code'), findsOneWidget);

      await _tapText(tester, 'Resend code');
      expect(find.text('Resend code in 1:00'), findsOneWidget);
    });

    testWidgets('a busy server asks to try again shortly', (tester) async {
      await openAfterRegistering(tester);
      _demo.update(const DemoSettings(code: DemoCode.unavailable));

      await _typeCode(tester, '481729');

      expect(find.text('The service is busy'), findsOneWidget);
      expect(find.text('Please try again shortly.'), findsOneWidget);
    });

    testWidgets('Change email goes back to the form', (tester) async {
      await openAfterRegistering(tester);

      await _tapText(tester, 'Change email');

      expect(find.byType(RegisterScreen), findsOneWidget);
    });
  });

  group('Forgot password', () {
    testWidgets('code, new password and sign in', (tester) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      await _tapText(tester, 'Forgot password?');

      await _typeInField(tester, 0, 'me@example.com');
      await _tapText(tester, 'Send code');
      expect(find.byType(ResetCodeScreen), findsOneWidget);
      expect(find.textContaining('me@example.com'), findsOneWidget);
      // The hint is for a new account only.
      expect(
        find.textContaining('You may already have an account'),
        findsNothing,
      );

      await _typeCode(tester, '620517');
      expect(find.byType(NewPasswordScreen), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      await _typeInField(tester, 0, 'secret123');
      await _typeInField(tester, 1, 'secret123');
      await _tapText(tester, 'Save password');
      expect(find.byType(PasswordChangedScreen), findsOneWidget);

      await _tapText(tester, 'Sign in');
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('the new password has no rules but being typed twice', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _go(tester, AppRoutes.newPassword);
      bool enabled() =>
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed !=
          null;

      expect(find.textContaining('characters'), findsNothing);
      expect(find.text('One number'), findsNothing);

      await _typeInField(tester, 0, 'x');
      await _typeInField(tester, 1, 'y');
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(enabled(), isFalse);

      await _typeInField(tester, 1, 'x');
      expect(find.text('Passwords do not match.'), findsNothing);
      expect(enabled(), isTrue, reason: 'any password: the server judges it');
    });

    testWidgets('Back to sign in returns to the sign-in form', (tester) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      await _tapText(tester, 'Forgot password?');

      await _tapText(tester, 'Back to sign in');

      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('a wrong reset code shows the tries left', (tester) async {
      await _pumpApp(tester);
      await _go(tester, AppRoutes.resetCode);
      _demo.update(const DemoSettings(code: DemoCode.wrong));

      await _typeCode(tester, '620517');

      expect(find.byType(ResetCodeScreen), findsOneWidget);
      expect(
        find.text('The code is incorrect. 4 attempts left.'),
        findsOneWidget,
      );
    });
  });

  group('Forgot password: what the server answers', () {
    testWidgets('asking for a code again at once counts down the wait', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _go(tester, AppRoutes.forgotPassword);
      await _typeInField(tester, 0, 'me@example.com');
      await _tapText(tester, 'Send code');
      expect(find.byType(ResetCodeScreen), findsOneWidget);
      await _back(tester);

      await _tapText(tester, 'Send code');

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.text('Try again in 1:00'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Try again in 1:00'),
            )
            .onPressed,
        isNull,
      );

      _ticker.tick(0);
      await tester.pumpAndSettle();
      expect(find.text('Send code'), findsOneWidget);
    });

    testWidgets('a busy server asks to try again shortly', (tester) async {
      await _pumpApp(tester);
      await _go(tester, AppRoutes.forgotPassword);
      _demo.update(const DemoSettings(code: DemoCode.unavailable));
      await _typeInField(tester, 0, 'me@example.com');

      await _tapText(tester, 'Send code');

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.byType(FailureView), findsOneWidget);
      expect(find.byType(ResetCodeScreen), findsNothing);
    });
  });

  group('New password: what the server answers', () {
    Future<void> save(WidgetTester tester) async {
      await _go(tester, AppRoutes.newPassword);
      await _typeInField(tester, 0, 'secret123');
      await _typeInField(tester, 1, 'secret123');
      await _tapText(tester, 'Save password');
    }

    testWidgets('a refused password is explained under the field', (
      tester,
    ) async {
      await _pumpApp(tester);
      _demo.update(
        const DemoSettings(passwordReset: DemoPasswordReset.passwordRefused),
      );

      await save(tester);

      expect(find.byType(NewPasswordScreen), findsOneWidget);
      expect(
        find.text('Your password is too short. Use at least 15 characters.'),
        findsOneWidget,
      );

      // The reset is still open: typing again clears the message.
      _demo.update(const DemoSettings());
      await _typeInField(tester, 0, 'a much longer passphrase');
      await _typeInField(tester, 1, 'a much longer passphrase');
      expect(find.textContaining('too short'), findsNothing);
      await _tapText(tester, 'Save password');
      expect(find.byType(PasswordChangedScreen), findsOneWidget);
    });

    testWidgets('a reset that ran out starts again from the email', (
      tester,
    ) async {
      await _pumpApp(tester);
      _demo.update(
        const DemoSettings(passwordReset: DemoPasswordReset.tokenInvalid),
      );

      await save(tester);

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(
        find.text('This reset has expired. Ask for a new code.'),
        findsOneWidget,
      );
    });

    testWidgets('too many requests counts down on the button', (tester) async {
      await _pumpApp(tester);
      _demo.update(
        const DemoSettings(passwordReset: DemoPasswordReset.tooSoon),
      );

      await save(tester);

      expect(find.text('Try again in 0:30'), findsOneWidget);
      _ticker.tick(0);
      await tester.pumpAndSettle();
      expect(find.text('Save password'), findsOneWidget);
    });

    testWidgets('a busy server asks to try again shortly', (tester) async {
      await _pumpApp(tester);
      _demo.update(
        const DemoSettings(passwordReset: DemoPasswordReset.unavailable),
      );

      await save(tester);

      expect(find.byType(NewPasswordScreen), findsOneWidget);
      expect(find.byType(FailureView), findsOneWidget);
    });

    testWidgets('saving it signs a signed-in person out', (tester) async {
      await _pumpApp(tester, signedIn: true);

      await save(tester);

      expect(find.byType(PasswordChangedScreen), findsOneWidget);
      expect(_auth.isSignedIn, isFalse);
    });
  });

  group('App lock', () {
    testWidgets('the fingerprint opens the app', (tester) async {
      await _pumpApp(tester, signedIn: true);
      await _go(tester, AppRoutes.appLock);
      expect(find.byType(AppLockScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Unlock with fingerprint'));
      await tester.pumpAndSettle();

      expect(find.byType(OverviewScreen), findsOneWidget);
    });

    testWidgets('Use PIN opens the pad; any PIN opens the app', (tester) async {
      await _pumpApp(tester, signedIn: true);
      await _go(tester, AppRoutes.appLock);

      await _tapText(tester, 'Use PIN');
      expect(find.byType(PinEntryScreen), findsOneWidget);

      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.text(digit));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OverviewScreen), findsOneWidget);
    });

    testWidgets('Forgot PIN signs out and leads to sign in', (tester) async {
      await _pumpApp(tester, signedIn: true);
      await _go(tester, AppRoutes.pinEntry);

      await _tapText(tester, 'Forgot PIN?');

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(_auth.isSignedIn, isFalse);
    });

    testWidgets('a PIN is created by typing it twice', (tester) async {
      await _pumpApp(tester, signedIn: true);
      await _go(tester, AppRoutes.settings);
      await _go(tester, AppRoutes.createPin);
      expect(find.byType(CreatePinScreen), findsOneWidget);
      expect(find.text('Create a 4-digit PIN'), findsOneWidget);

      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.text(digit));
        await tester.pumpAndSettle();
      }
      expect(find.text('Repeat your PIN'), findsOneWidget);

      for (final digit in ['1', '2', '3', '4']) {
        await tester.tap(find.text(digit));
        await tester.pumpAndSettle();
      }
      expect(find.byType(CreatePinScreen), findsNothing);
    });

    testWidgets('different PINs ask to start again', (tester) async {
      await _pumpApp(tester, signedIn: true);
      await _go(tester, AppRoutes.createPin);

      for (final digit in ['1', '2', '3', '4', '4', '3', '2', '1']) {
        await tester.tap(find.text(digit));
        await tester.pumpAndSettle();
      }

      expect(find.text('The PINs do not match. Try again.'), findsOneWidget);
      expect(find.text('Create a 4-digit PIN'), findsOneWidget);
    });
  });
}
