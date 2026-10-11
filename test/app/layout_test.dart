import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/app/router/app_router.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../support/build_app.dart';
import '../support/fake_language_repository.dart';
import '../support/fake_push_messaging_repository.dart';

/// Every screen of the app. Add a new screen here: the test below fails when a
/// route is missing from this list.
const List<String> _screens = [
  AppRoutes.welcome,
  AppRoutes.signIn,
  AppRoutes.register,
  AppRoutes.verifyEmail,
  AppRoutes.emailVerified,
  AppRoutes.paySetup,
  AppRoutes.forgotPassword,
  AppRoutes.resetCode,
  AppRoutes.newPassword,
  AppRoutes.passwordChanged,
  AppRoutes.appLock,
  AppRoutes.pinEntry,
  AppRoutes.createPin,
  AppRoutes.overview,
  AppRoutes.salary,
  AppRoutes.transactions,
  AppRoutes.debts,
  AppRoutes.reports,
  AppRoutes.settings,
  AppRoutes.demo,
];

const Map<AppLanguage, TextDirection> _languages = {
  AppLanguage.english: TextDirection.ltr,
  AppLanguage.arabic: TextDirection.rtl,
};

/// The paths of all the routes of [routes], also those inside the tabs of the
/// navigation shell.
Iterable<String> _paths(List<RouteBase> routes) sync* {
  for (final route in routes) {
    if (route is GoRoute) yield route.path;
    yield* _paths(route.routes);
  }
}

Future<void> _openScreen(
  WidgetTester tester,
  String route,
  AppLanguage language,
) async {
  tester.view
    ..devicePixelRatio = 3
    ..physicalSize = const Size(360 * 3, 640 * 3);
  addTearDown(tester.view.reset);

  // The screens of the sign-in flow are for a signed-out person, the others
  // for a signed-in one.
  final signedIn = !AppRoutes.withoutSignIn.contains(route);
  final demo = DemoController(latency: Duration.zero);

  await tester.pumpWidget(
    buildApp(
      languageRepository: FakeLanguageRepository(language),
      // Push available and not yet allowed, so every row and button is shown.
      pushMessaging: FakePushMessagingRepository(),
      demo: demo,
      authRepository: FakeAuthRepository(demo: demo, signedIn: signedIn),
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
  await tester.pumpAndSettle();
}

void main() {
  test('this list covers every route of the app', () {
    final demo = DemoController(latency: Duration.zero);
    final auth = FakeAuthRepository(demo: demo);
    final router = createAppRouter(auth: auth, refreshListenable: _Never());
    addTearDown(router.dispose);

    expect(_screens, unorderedEquals(_paths(router.configuration.routes)));
  });

  for (final route in _screens) {
    for (final MapEntry(key: language, value: direction)
        in _languages.entries) {
      group('$route in ${language.name}', () {
        testWidgets('is laid out $direction', (tester) async {
          await _openScreen(tester, route, language);

          final context = tester.element(find.byType(Scaffold).first);
          expect(Directionality.of(context), direction);
          expect(tester.takeException(), isNull);
        });

        testWidgets('fits at 200% text size', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await _openScreen(tester, route, language);

          expect(tester.takeException(), isNull);
        });
      });
    }
  }

  testWidgets('the app bar mirrors in Arabic', (tester) async {
    await _openScreen(tester, AppRoutes.overview, AppLanguage.arabic);
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final title = tester
        .getCenter(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('نظرة عامة'),
          ),
        )
        .dx;
    final settings = tester.getCenter(find.byIcon(Icons.settings_outlined)).dx;

    expect(title, greaterThan(width / 2), reason: 'title starts on the right');
    expect(settings, lessThan(width / 2), reason: 'action ends on the left');
  });

  testWidgets('the back arrow sits on the right in Arabic', (tester) async {
    await _openScreen(tester, AppRoutes.signIn, AppLanguage.arabic);
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;

    expect(
      tester.getCenter(find.byType(BackButton)).dx,
      greaterThan(width / 2),
    );
  });
}

/// A listenable that never changes.
class _Never extends ChangeNotifier {
  new();
}
