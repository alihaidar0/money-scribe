import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/app/router/app_router.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../support/build_app.dart';
import '../support/fake_language_repository.dart';

/// Every screen of the app. Add a new screen here: the test below fails when a
/// route is missing from this list.
const List<String> _screens = [AppRoutes.overview, AppRoutes.settings];

const Map<AppLanguage, TextDirection> _languages = {
  AppLanguage.english: TextDirection.ltr,
  AppLanguage.arabic: TextDirection.rtl,
};

Future<void> _openScreen(
  WidgetTester tester,
  String route,
  AppLanguage language,
) async {
  tester.view
    ..devicePixelRatio = 3
    ..physicalSize = const Size(360 * 3, 640 * 3);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    buildApp(languageRepository: FakeLanguageRepository(language)),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  container.read(appRouterProvider).go(route);
  await tester.pumpAndSettle();
}

void main() {
  test('this list covers every route of the app', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final routes = container
        .read(appRouterProvider)
        .configuration
        .routes
        .whereType<GoRoute>()
        .map((route) => route.path);

    expect(_screens, unorderedEquals(routes));
  });

  for (final route in _screens) {
    for (final MapEntry(key: language, value: direction)
        in _languages.entries) {
      group('$route in ${language.name}', () {
        testWidgets('is laid out $direction', (tester) async {
          await _openScreen(tester, route, language);

          final context = tester.element(find.byType(Scaffold));
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
    final title = tester.getCenter(find.text('نظرة عامة')).dx;
    final settings = tester.getCenter(find.byIcon(Icons.settings_outlined)).dx;

    expect(title, greaterThan(width / 2), reason: 'title starts on the right');
    expect(settings, lessThan(width / 2), reason: 'action ends on the left');
  });

  testWidgets('the back arrow sits on the right in Arabic', (tester) async {
    await _openScreen(tester, AppRoutes.overview, AppLanguage.arabic);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;

    expect(
      tester.getCenter(find.byType(BackButton)).dx,
      greaterThan(width / 2),
    );
  });
}
