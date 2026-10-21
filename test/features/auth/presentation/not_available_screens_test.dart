import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/auth/presentation/change_password_screen.dart';
import 'package:money_scribe/features/auth/presentation/forgot_password_screen.dart';
import 'package:money_scribe/features/auth/presentation/sign_in_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/build_app.dart';
import '../../../support/fake_language_repository.dart';
import '../../../support/not_available_auth_repository.dart';

/// What the real server offers today: no reset, no change of password, no
/// deleting the account. Each screen says so instead of failing.
Future<void> _open(
  WidgetTester tester, {
  required String route,
  required bool signedIn,
  AppLanguage language = AppLanguage.english,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(412, 1800);
  addTearDown(tester.view.reset);
  final demo = DemoController(latency: Duration.zero);
  await tester.pumpWidget(
    buildApp(
      demo: demo,
      languageRepository: FakeLanguageRepository(language),
      authRepository: NotAvailableAuthRepository(
        demo: demo,
        signedIn: signedIn,
      ),
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
  await tester.pumpAndSettle();
}

Future<void> _push(WidgetTester tester, String route) async {
  unawaited(
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push<void>(route),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Forgot password', () {
    Future<void> openForgotPassword(WidgetTester tester) async {
      await _open(tester, route: AppRoutes.signIn, signedIn: false);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'me@example.com');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
    }

    testWidgets('says it is not available yet, with no way to retry', (
      tester,
    ) async {
      await openForgotPassword(tester);

      expect(find.text('Not available yet'), findsOneWidget);
      expect(
        find.text(
          'This part of your account is not ready on the server yet. It will '
          'be added soon.',
        ),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('Go back returns to the previous screen', (tester) async {
      await openForgotPassword(tester);

      await tester.tap(find.text('Go back'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(ForgotPasswordScreen), findsNothing);
    });

    testWidgets('is in Arabic too', (tester) async {
      await _open(
        tester,
        route: AppRoutes.signIn,
        signedIn: false,
        language: AppLanguage.arabic,
      );
      await tester.tap(find.text('نسيت كلمة المرور؟'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'me@example.com');
      await tester.tap(find.text('إرسال الرمز'));
      await tester.pumpAndSettle();

      expect(find.text('غير متاح بعد'), findsOneWidget);
      expect(find.text('رجوع'), findsOneWidget);
    });
  });

  group('Change password', () {
    testWidgets('says it is not available yet when saving', (tester) async {
      await _open(tester, route: AppRoutes.account, signedIn: true);
      await _push(tester, AppRoutes.changePassword);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'old');
      await tester.enterText(fields.at(1), 'new passphrase');
      await tester.enterText(fields.at(2), 'new passphrase');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save password'));
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordScreen), findsOneWidget);
      expect(find.byType(FailureView), findsOneWidget);
      expect(find.text('Not available yet'), findsOneWidget);
    });

    testWidgets('Go back returns to the account', (tester) async {
      await _open(tester, route: AppRoutes.account, signedIn: true);
      await _push(tester, AppRoutes.changePassword);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'old');
      await tester.enterText(fields.at(1), 'x');
      await tester.enterText(fields.at(2), 'x');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save password'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go back'));
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordScreen), findsNothing);
    });
  });

  group('Delete account', () {
    testWidgets('says it is not available yet, and keeps the dialog', (
      tester,
    ) async {
      await _open(tester, route: AppRoutes.account, signedIn: true);
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'my password',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Delete account'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Deleting your account is not available yet.'),
        findsOneWidget,
      );
      expect(find.text('Wrong password'), findsNothing);
    });
  });
}
