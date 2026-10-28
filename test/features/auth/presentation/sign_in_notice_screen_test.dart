import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/widgets/message_banner.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/domain/sign_out_reason.dart';
import 'package:money_scribe/features/auth/presentation/sign_in_screen.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/build_app.dart';
import '../../../support/fake_language_repository.dart';
import '../../../support/fake_ticker.dart';

late DemoController _demo;
late FakeAuthRepository _auth;

/// Opens the app signed in, then lets the server sign the device out for
/// [reason]: the app moves to the Sign in screen by itself.
Future<void> _signedOutBy(
  WidgetTester tester,
  SignOutReason reason, {
  AppLanguage language = AppLanguage.english,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(412, 915);
  addTearDown(tester.view.reset);
  _demo = DemoController(latency: Duration.zero);
  _auth = FakeAuthRepository(demo: _demo, signedIn: true);

  await tester.pumpWidget(
    buildApp(
      demo: _demo,
      ticker: FakeTicker(),
      authRepository: _auth,
      languageRepository: FakeLanguageRepository(language),
    ),
  );
  await tester.pumpAndSettle();
  _auth.endSession(reason);
  await tester.pumpAndSettle();
}

Finder get _notice => find.byType(MessageBanner);

String _noticeText(WidgetTester tester) {
  return tester.widget<MessageBanner>(find.byType(MessageBanner).first).text;
}

void main() {
  const english = {
    SignOutReason.tooManyDevices:
        'You were signed out because your account is signed in on too many '
        'devices. Sign in again to continue.',
    SignOutReason.endedElsewhere:
        'You were signed out from another device. Sign in again to continue.',
    SignOutReason.passwordChanged:
        'You were signed out because the password of your account was '
        'changed. Sign in with the new password.',
    SignOutReason.emailChanged:
        'You were signed out because the email of your account was changed. '
        'Sign in with the new email.',
    SignOutReason.security:
        'You were signed out to keep your account safe. Sign in again to '
        'continue.',
    SignOutReason.expired:
        'Your session has expired. Sign in again to continue.',
    SignOutReason.other: 'You were signed out. Sign in again to continue.',
  };

  for (final reason in SignOutReason.values) {
    testWidgets('says why for ${reason.name}', (tester) async {
      await _signedOutBy(tester, reason);

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(_noticeText(tester), english[reason]);
      final banner = tester.widget<MessageBanner>(_notice);
      expect(banner.tone, BannerTone.info);
    });
  }

  testWidgets('says it in Arabic', (tester) async {
    await _signedOutBy(
      tester,
      SignOutReason.tooManyDevices,
      language: AppLanguage.arabic,
    );

    expect(_noticeText(tester), contains('أجهزة كثيرة جدًا'));
  });

  testWidgets('the next attempt replaces it with its own answer', (
    tester,
  ) async {
    await _signedOutBy(tester, SignOutReason.passwordChanged);
    _demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));

    await tester.enterText(find.byType(TextField).first, 'alex@example.com');
    await tester.enterText(find.byType(TextField).last, 'old password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(_notice, findsNothing);
    expect(find.text('Wrong password.'), findsOneWidget);
  });

  testWidgets('signing in opens the app and forgets it', (tester) async {
    await _signedOutBy(tester, SignOutReason.endedElsewhere);

    await tester.enterText(find.byType(TextField).first, 'alex@example.com');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.byType(OverviewScreen), findsOneWidget);
    expect(_auth.signOutReason, isNull);
  });

  testWidgets('going back to Welcome and on to Sign in still says why', (
    tester,
  ) async {
    await _signedOutBy(tester, SignOutReason.expired);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();

    // The reason stays true until the person signs in or out themselves.
    expect(_noticeText(tester), english[SignOutReason.expired]);
  });
}
