import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/data/fake/fake_device_key_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_exception.dart';
import 'package:money_scribe/features/auth/presentation/sign_in_screen.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/build_app.dart';
import '../../../support/fake_language_repository.dart';
import '../../../support/fake_ticker.dart';

/// A phone whose key stopped working: a fingerprint was added, so the phone
/// deletes the key and says so.
class _InvalidatedKeys extends FakeDeviceKeyRepository {
  new({required super.demo, required super.auth});

  @override
  Future<void> signIn({required String prompt}) async {
    await forgetLocal();
    throw const FingerprintKeyInvalidatedException();
  }
}

late DemoController _demo;
late FakeAuthRepository _auth;
late FakeDeviceKeyRepository _keys;

/// Opens the app signed out, on a phone whose fingerprint signs the sample
/// account in (or on one with no key), and goes to the Sign in screen.
Future<void> _pumpSignIn(
  WidgetTester tester, {
  bool hasKey = true,
  AppLanguage language = AppLanguage.english,
  FakeDeviceKeyRepository Function(
    DemoController demo,
    FakeAuthRepository auth,
  )?
  makeKeys,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(412, 915);
  addTearDown(tester.view.reset);
  _demo = DemoController(latency: Duration.zero);
  _auth = FakeAuthRepository(demo: _demo, signedIn: true);
  _keys =
      makeKeys?.call(_demo, _auth) ??
      FakeDeviceKeyRepository(demo: _demo, auth: _auth);
  if (hasKey) await _keys.enable(password: 'p', prompt: 'Confirm');
  await _auth.signOut();

  await tester.pumpWidget(
    buildApp(
      demo: _demo,
      ticker: FakeTicker(),
      authRepository: _auth,
      deviceKeyRepository: _keys,
      languageRepository: FakeLanguageRepository(language),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.text(language == AppLanguage.arabic ? 'تسجيل الدخول' : 'Sign in').last,
  );
  await tester.pumpAndSettle();
}

Finder get _fingerprintButton =>
    find.widgetWithText(FilledButton, 'Sign in with fingerprint');

Finder get _otherAccount => find.text('Use another account');

Future<void> _press(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('a phone with a fingerprint key', () {
    testWidgets('offers the account and the fingerprint first', (tester) async {
      await _pumpSignIn(tester);
      final account = (await _keys.signInAccount())!;

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('Sign in as ${account.name}'), findsOneWidget);
      expect(find.text(account.maskedEmail), findsOneWidget);
      expect(_fingerprintButton, findsOneWidget);
      expect(_otherAccount, findsOneWidget);
      // No form until the person asks for it.
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Forgot password?'), findsNothing);
      // The way to create an account stays.
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('the fingerprint signs in and opens the app', (tester) async {
      await _pumpSignIn(tester);

      await _press(tester, _fingerprintButton);

      expect(_auth.isSignedIn, isTrue);
      expect(find.byType(OverviewScreen), findsOneWidget);
    });

    testWidgets('Use another account shows the form, and the key stays', (
      tester,
    ) async {
      await _pumpSignIn(tester);

      await _press(tester, _otherAccount);

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(_fingerprintButton, findsNothing);
      expect(await _keys.signInAccount(), isNotNull);
    });

    testWidgets('the form still signs in with a password', (tester) async {
      await _pumpSignIn(tester);
      await _press(tester, _otherAccount);

      await tester.enterText(find.byType(TextField).first, 'a@b.c');
      await tester.enterText(find.byType(TextField).last, 'x');
      await _press(tester, find.widgetWithText(FilledButton, 'Sign in'));

      expect(_auth.isSignedIn, isTrue);
    });

    testWidgets('says nothing when the fingerprint did not match', (
      tester,
    ) async {
      await _pumpSignIn(tester);
      _demo.update(const DemoSettings(fingerprint: DemoFingerprint.notMatched));

      await _press(tester, _fingerprintButton);

      expect(_auth.isSignedIn, isFalse);
      expect(_fingerprintButton, findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('says the phone cannot check it now, and keeps it', (
      tester,
    ) async {
      await _pumpSignIn(tester);
      _demo.update(
        const DemoSettings(fingerprint: DemoFingerprint.notEnrolled),
      );

      await _press(tester, _fingerprintButton);

      expect(
        find.text(
          "The fingerprint can't be checked right now. Try again later or use "
          'your password.',
        ),
        findsOneWidget,
      );
      expect(_fingerprintButton, findsOneWidget);
    });

    testWidgets('a refused key points to the password and shows the form', (
      tester,
    ) async {
      await _pumpSignIn(tester);
      _demo.update(
        const DemoSettings(fingerprint: DemoFingerprint.signInRefused),
      );

      await _press(tester, _fingerprintButton);

      expect(
        find.text(
          "Fingerprint sign-in didn't work. Use your password to sign in.",
        ),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNWidgets(2));
      expect(_fingerprintButton, findsNothing);
    });

    testWidgets('a key that stopped working is gone, and says why', (
      tester,
    ) async {
      await _pumpSignIn(
        tester,
        makeKeys: (demo, auth) => _InvalidatedKeys(demo: demo, auth: auth),
      );

      await _press(tester, _fingerprintButton);

      expect(
        find.textContaining('A fingerprint was added or removed'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNWidgets(2));
      expect(await _keys.signInAccount(), isNull);
    });

    testWidgets('locks with a countdown, and the button waits', (tester) async {
      await _pumpSignIn(tester);
      _demo.update(const DemoSettings(fingerprint: DemoFingerprint.locked));

      await _press(tester, _fingerprintButton);

      expect(
        find.text('Too many attempts. Try again in 5:00.'),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(_fingerprintButton).onPressed, isNull);
      // The password form is still one press away.
      expect(_otherAccount, findsOneWidget);
    });

    testWidgets('no connection offers Try again, which asks for it again', (
      tester,
    ) async {
      await _pumpSignIn(tester);
      _demo.update(const DemoSettings(scenario: DemoScenario.noConnection));

      await _press(tester, _fingerprintButton);
      expect(find.text('No connection'), findsOneWidget);

      _demo.update(const DemoSettings());
      await _press(tester, find.text('Try again'));

      expect(_auth.isSignedIn, isTrue);
    });
  });

  group('a phone with no key', () {
    testWidgets('shows only the form', (tester) async {
      await _pumpSignIn(tester, hasKey: false);

      expect(find.byType(TextField), findsNWidgets(2));
      expect(_fingerprintButton, findsNothing);
      expect(_otherAccount, findsNothing);
    });
  });

  group('layout', () {
    testWidgets('fits at 200% text size', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _pumpSignIn(tester);

      expect(tester.takeException(), isNull);
      expect(_fingerprintButton, findsOneWidget);
    });

    testWidgets('is in Arabic, with the address kept left to right', (
      tester,
    ) async {
      await _pumpSignIn(tester, language: AppLanguage.arabic);
      final account = (await _keys.signInAccount())!;

      expect(
        find.widgetWithText(FilledButton, 'تسجيل الدخول بالبصمة'),
        findsOneWidget,
      );
      expect(find.text('استخدام حساب آخر'), findsOneWidget);
      expect(find.text('تسجيل الدخول باسم ${account.name}'), findsOneWidget);
      expect(find.text(account.maskedEmail), findsOneWidget);
    });
  });
}
