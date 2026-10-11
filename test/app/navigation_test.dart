import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
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

Future<void> _pumpApp(WidgetTester tester, {bool signedIn = false}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(412, 915);
  addTearDown(tester.view.reset);
  _demo = DemoController(latency: Duration.zero);
  _ticker = FakeTicker();
  _auth = FakeAuthRepository(demo: _demo, signedIn: signedIn);
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

    testWidgets('a wrong password shows the error and stays on the form', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Sign in');
      _demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));

      await _tapButton(tester, FilledButton);

      expect(find.text('Email or password is incorrect.'), findsOneWidget);
      expect(find.byType(SignInScreen), findsOneWidget);
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
      await _typeInField(tester, 2, 'a');
      await _typeInField(tester, 3, 'b');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await _tapButton(tester, FilledButton);
    }

    testWidgets('the button waits for the agreement', (tester) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Create account');

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
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

      await _typeCode(tester, '4817');
      expect(find.byType(EmailVerifiedScreen), findsOneWidget);
      expect(find.text('Your account is ready.'), findsOneWidget);

      await _tapText(tester, 'Continue');
      expect(find.byType(PaySetupScreen), findsOneWidget);

      await _tapText(tester, 'Continue');
      expect(find.byType(OverviewScreen), findsOneWidget);
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

    testWidgets('refused data show the errors; the Sign in link leads on', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Create account');
      _demo.update(const DemoSettings(registration: DemoRegistration.rejected));

      await fillAndSubmit(tester);

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(
        find.textContaining('already registered', findRichText: true),
        findsOneWidget,
      );
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
    Future<void> openCodeScreen(WidgetTester tester) async {
      await _pumpApp(tester);
      await _go(tester, AppRoutes.verifyEmail);
    }

    testWidgets('waits for four digits before Verify can be pressed', (
      tester,
    ) async {
      await openCodeScreen(tester);
      bool enabled() =>
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed !=
          null;

      expect(enabled(), isFalse);
      await _typeCode(tester, '48');
      expect(enabled(), isFalse);
      expect(find.text('Resend code in 1:00'), findsOneWidget);
    });

    testWidgets('a wrong code shows the tries left', (tester) async {
      await openCodeScreen(tester);
      _demo.update(const DemoSettings(code: DemoCode.wrong));

      await _typeCode(tester, '4817');
      expect(
        find.text('The code is incorrect. 2 attempts left.'),
        findsOneWidget,
      );

      await _typeCode(tester, '481');
      expect(find.textContaining('incorrect'), findsNothing);

      await _typeCode(tester, '4818');
      expect(
        find.text('The code is incorrect. 1 attempt left.'),
        findsOneWidget,
      );

      await _typeCode(tester, '481');
      await _typeCode(tester, '4819');
      expect(find.text('This code has expired.'), findsOneWidget);
    });

    testWidgets('an expired code can be replaced', (tester) async {
      await openCodeScreen(tester);
      _demo.update(const DemoSettings(code: DemoCode.expired));
      await _typeCode(tester, '4817');

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

    testWidgets('counts down to Resend code', (tester) async {
      await openCodeScreen(tester);

      _ticker.tick(42);
      await tester.pumpAndSettle();
      expect(find.text('Resend code in 0:42'), findsOneWidget);

      _ticker.tick(0);
      await tester.pumpAndSettle();
      expect(find.text('Resend code in 0:00'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Resend code'), findsOneWidget);

      await _tapText(tester, 'Resend code');
      expect(find.text('Resend code in 1:00'), findsOneWidget);
    });

    testWidgets('Change email goes back to the form', (tester) async {
      await _pumpApp(tester);
      await _tapText(tester, 'Create account');
      await _typeInField(tester, 1, 'alex@example.com');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await _tapButton(tester, FilledButton);
      expect(find.byType(VerifyEmailScreen), findsOneWidget);

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

      await _typeCode(tester, '6205');
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

    testWidgets('the checklist follows the typing', (tester) async {
      await _pumpApp(tester);
      await _go(tester, AppRoutes.newPassword);
      IconData iconOf(String rule) {
        final row = find.ancestor(
          of: find.text(rule),
          matching: find.byType(Row),
        );
        return tester
            .widget<Icon>(
              find.descendant(of: row.first, matching: find.byType(Icon)),
            )
            .icon!;
      }

      expect(iconOf('At least 8 characters'), Icons.radio_button_unchecked);

      await _typeInField(tester, 0, 'secret123');
      expect(iconOf('At least 8 characters'), Icons.check_circle);
      expect(iconOf('One number'), Icons.check_circle);
      expect(iconOf('Passwords match'), Icons.radio_button_unchecked);
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

      await _typeCode(tester, '6205');

      expect(find.byType(ResetCodeScreen), findsOneWidget);
      expect(
        find.text('The code is incorrect. 2 attempts left.'),
        findsOneWidget,
      );
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
