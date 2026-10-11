import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../support/build_app.dart';
import '../support/fake_language_repository.dart';
import '../support/render_screen.dart';

/// The render check: every screen and state is drawn to a picture in English
/// and Arabic, light and dark, into `build/screens/`, to be looked at. The test
/// also fails if a screen throws.

typedef _Setup = Future<void> Function(
  WidgetTester tester,
  DemoController demo,
);

class _Scene {
  const new(
    this.name,
    this.route, {
    this.signedIn = false,
    this.setup,
    this.size = const Size(412, 915),
  });

  final String name;
  final String route;
  final bool signedIn;
  final _Setup? setup;
  final Size size;
}

Future<void> _typeCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.pumpAndSettle();
}

Future<void> _tapPrimary(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton).first);
  await tester.pumpAndSettle();
}

Future<void> _tapKeys(WidgetTester tester, List<int> digits) async {
  for (final digit in digits) {
    await tester.tap(find.text('$digit'));
    await tester.pumpAndSettle();
  }
}

final _scenes = <_Scene>[
  const _Scene('auth-1-welcome', AppRoutes.welcome),
  const _Scene('auth-2-sign-in', AppRoutes.signIn),
  _Scene(
    'auth-2b-sign-in-wrong',
    AppRoutes.signIn,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-2c-sign-in-locked',
    AppRoutes.signIn,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(signIn: DemoSignIn.locked));
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'nc-1-no-connection',
    AppRoutes.signIn,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'err-2-something-went-wrong',
    AppRoutes.signIn,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(scenario: DemoScenario.error));
      await _tapPrimary(tester);
    },
  ),
  const _Scene('auth-3-register', AppRoutes.register),
  _Scene(
    'auth-3-register-filled',
    AppRoutes.register,
    setup: (tester, demo) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Alex');
      await tester.enterText(fields.at(1), 'alex@example.com');
      await tester.enterText(fields.at(2), 'password1');
      await tester.enterText(fields.at(3), 'password1');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
    },
  ),
  _Scene(
    'auth-3b-register-errors',
    AppRoutes.register,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(registration: DemoRegistration.rejected));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Alex');
      await tester.enterText(fields.at(1), 'alex@example.com');
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await _tapPrimary(tester);
    },
  ),
  _Scene(
    'auth-4-verify-email',
    AppRoutes.verifyEmail,
    setup: (tester, demo) => _typeCode(tester, '48'),
  ),
  _Scene(
    'auth-4b-verify-wrong',
    AppRoutes.verifyEmail,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(code: DemoCode.wrong));
      await _typeCode(tester, '4817');
    },
  ),
  _Scene(
    'auth-4c-verify-expired',
    AppRoutes.verifyEmail,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(code: DemoCode.expired));
      await _typeCode(tester, '4817');
    },
  ),
  const _Scene(
    'auth-5-email-verified',
    AppRoutes.emailVerified,
    signedIn: true,
  ),
  const _Scene('auth-6-pay-setup', AppRoutes.paySetup, signedIn: true),
  _Scene(
    'auth-6b-pay-setup-two',
    AppRoutes.paySetup,
    signedIn: true,
    setup: (tester, demo) async {
      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pumpAndSettle();
    },
  ),
  const _Scene('auth-7-forgot-password', AppRoutes.forgotPassword),
  _Scene(
    'auth-8-reset-code',
    AppRoutes.resetCode,
    setup: (tester, demo) => _typeCode(tester, '6'),
  ),
  _Scene(
    'auth-8b-reset-wrong',
    AppRoutes.resetCode,
    setup: (tester, demo) async {
      demo.update(const DemoSettings(code: DemoCode.wrong));
      await _typeCode(tester, '6205');
    },
  ),
  _Scene(
    'auth-9-new-password',
    AppRoutes.newPassword,
    setup: (tester, demo) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'secret123');
      await tester.enterText(fields.at(1), 'secret123');
      await tester.pumpAndSettle();
    },
  ),
  const _Scene('auth-10-password-changed', AppRoutes.passwordChanged),
  const _Scene('auth-11-app-lock', AppRoutes.appLock),
  _Scene(
    'auth-12-pin-entry',
    AppRoutes.pinEntry,
    setup: (tester, demo) => _tapKeys(tester, [3, 7]),
  ),
  _Scene(
    'auth-13-create-pin',
    AppRoutes.createPin,
    signedIn: true,
    setup: (tester, demo) => _tapKeys(tester, [3]),
  ),
  const _Scene('shell-overview', AppRoutes.overview, signedIn: true),
  const _Scene(
    'shell-overview-wide',
    AppRoutes.overview,
    signedIn: true,
    size: Size(1280, 800),
  ),
  const _Scene('settings', AppRoutes.settings, signedIn: true),
  const _Scene('demo-panel', AppRoutes.demo),
];

void main() {
  setUpAll(loadAppFonts);

  for (final scene in _scenes) {
    for (final language in [AppLanguage.english, AppLanguage.arabic]) {
      for (final brightness in Brightness.values) {
        final name = '${scene.name}-${language.name}-${brightness.name}';

        testWidgets('draws $name', (tester) async {
          tester.view
            ..devicePixelRatio = 1
            ..physicalSize = scene.size;
          addTearDown(tester.view.reset);
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );

          final demo = DemoController(latency: Duration.zero);
          final key = GlobalKey();
          await tester.pumpWidget(
            RenderTarget(
              boundaryKey: key,
              child: buildApp(
                languageRepository: FakeLanguageRepository(language),
                demo: demo,
                authRepository: FakeAuthRepository(
                  demo: demo,
                  signedIn: scene.signedIn,
                ),
                // The demo panel handle belongs to staging builds only and
                // would sit on top of every picture.
                environment: scene.route == AppRoutes.demo
                    ? AppEnvironment.staging
                    : AppEnvironment.production,
              ),
            ),
          );
          await tester.pumpAndSettle();
          GoRouter.of(tester.element(find.byType(Scaffold).first))
              .go(scene.route);
          await tester.pumpAndSettle();
          await scene.setup?.call(tester, demo);

          expect(tester.takeException(), isNull);
          await saveScreenshot(tester, key, name);
        });
      }
    }
  }
}
