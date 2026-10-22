import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/app/demo/demo_handle.dart';
import 'package:money_scribe/app/demo/demo_panel_screen.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/auth/presentation/app_lock_screen.dart';
import 'package:money_scribe/features/auth/presentation/welcome_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../support/build_app.dart';
import '../../support/fake_language_repository.dart';

void main() {
  testWidgets('staging builds have the demo handle', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(DemoHandle), findsOneWidget);
  });

  testWidgets('production builds never have it', (tester) async {
    await tester.pumpWidget(buildApp(environment: AppEnvironment.production));
    await tester.pumpAndSettle();

    expect(find.byType(DemoHandle), findsNothing);
  });

  testWidgets('the handle opens the panel, once', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DemoHandle));
    await tester.pumpAndSettle();
    expect(find.byType(DemoPanelScreen), findsOneWidget);

    await tester.tap(find.byType(DemoHandle));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  group('the panel', () {
    late DemoController demo;

    Future<void> openPanel(
      WidgetTester tester, {
      FakeLanguageRepository? language,
      bool signedIn = false,
    }) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(412, 3200);
      addTearDown(tester.view.reset);
      demo = DemoController(latency: Duration.zero);
      await tester.pumpWidget(
        buildApp(
          demo: demo,
          languageRepository: language,
          authRepository: FakeAuthRepository(demo: demo, signedIn: signedIn),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DemoHandle));
      await tester.pumpAndSettle();
    }

    testWidgets('changes what the fake data answers', (tester) async {
      await openPanel(tester);

      await tester.tap(find.text('No connection'));
      await tester.tap(find.text('Wrong password (locks after 5)'));
      await tester.tap(find.text('Rejected (field errors)'));
      await tester.tap(find.text('Expired'));
      await tester.tap(find.text('Two payments (parts)'));
      await tester.pumpAndSettle();

      expect(
        demo.settings,
        const DemoSettings(
          scenario: DemoScenario.noConnection,
          signIn: DemoSignIn.wrongPassword,
          registration: DemoRegistration.rejected,
          code: DemoCode.expired,
          paymentMode: PaymentMode.twoPayments,
        ),
      );
    });

    testWidgets('leaves out the account switches when the account is real', (
      tester,
    ) async {
      final real = DemoController(latency: Duration.zero, fakeAccount: false);
      await tester.pumpWidget(
        buildApp(
          demo: real,
          authRepository: FakeAuthRepository(demo: real, signedIn: true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DemoHandle));
      await tester.pumpAndSettle();

      expect(find.text('Sign in, next attempt'), findsNothing);
      expect(find.text('Create account, next attempt'), findsNothing);
      expect(find.text('6-digit codes and new codes'), findsNothing);
      expect(
        find.textContaining('The account is on the real server'),
        findsOneWidget,
      );
      // The switches of the screens that are still fake stay.
      expect(find.text('Server'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('shows the account switches while the account is fake', (
      tester,
    ) async {
      await openPanel(tester);

      expect(find.text('Sign in, next attempt'), findsOneWidget);
      expect(find.text('6-digit codes and new codes'), findsOneWidget);
    });

    testWidgets('switches the theme of the app', (tester) async {
      await openPanel(tester);
      ThemeMode themeMode() =>
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
      expect(themeMode(), ThemeMode.system);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(themeMode(), ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(DemoPanelScreen))).brightness,
        Brightness.dark,
      );

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(themeMode(), ThemeMode.light);
      expect(
        Theme.of(tester.element(find.byType(DemoPanelScreen))).brightness,
        Brightness.light,
      );
    });

    testWidgets('makes the next save fail', (tester) async {
      await openPanel(tester);

      await tester.tap(find.text('Fails (could not save)'));
      await tester.pumpAndSettle();

      expect(demo.settings.save, DemoSave.fails);
    });

    testWidgets('shows the current choices', (tester) async {
      await openPanel(tester);

      final group = find.byType(RadioGroup<DemoScenario>);
      expect(
        tester.widget<RadioGroup<DemoScenario>>(group).groupValue,
        DemoScenario.normal,
      );
    });

    testWidgets('switches the language of the app', (tester) async {
      final language = FakeLanguageRepository();
      await openPanel(tester, language: language);

      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();

      expect(language.language, AppLanguage.arabic);
    });

    testWidgets('jumps to the screens no button leads to', (tester) async {
      await openPanel(tester, signedIn: true);

      await tester.tap(find.text('App lock (AUTH-11)'));
      await tester.pumpAndSettle();

      expect(find.byType(AppLockScreen), findsOneWidget);
    });

    testWidgets('signs out and shows Welcome', (tester) async {
      await openPanel(tester, signedIn: true);

      await tester.tap(find.text('Sign out and show Welcome'));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      GoRouter.of(tester.element(find.byType(Scaffold).first));
    });
  });
}
