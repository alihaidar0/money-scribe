import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../support/build_app.dart';
import '../support/fake_language_repository.dart';

TextDirection _direction(WidgetTester tester) {
  return Directionality.of(tester.element(find.byType(OverviewScreen)));
}

void _setDeviceLanguage(WidgetTester tester, String languageCode) {
  tester.platformDispatcher.localesTestValue = [Locale(languageCode)];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}

void main() {
  testWidgets('the app starts on the overview screen', (tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.byType(OverviewScreen), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
  });

  testWidgets('the app follows the system between the light and dark themes', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.theme, AppTheme.light);
    expect(app.darkTheme, AppTheme.dark);
    expect(app.themeMode, ThemeMode.system);
  });

  testWidgets('the app title is the translated app name', (tester) async {
    await tester.pumpWidget(buildApp());

    expect(tester.widget<Title>(find.byType(Title)).title, 'Money Scribe');
  });

  group('language', () {
    testWidgets('follows an Arabic device, mirrored right to left', (
      tester,
    ) async {
      _setDeviceLanguage(tester, 'ar');
      await tester.pumpWidget(buildApp());

      expect(find.text('نظرة عامة'), findsOneWidget);
      expect(_direction(tester), TextDirection.rtl);
    });

    testWidgets('falls back to English on an unsupported device language', (
      tester,
    ) async {
      _setDeviceLanguage(tester, 'fr');
      await tester.pumpWidget(buildApp());

      expect(find.text('Overview'), findsOneWidget);
      expect(_direction(tester), TextDirection.ltr);
    });

    testWidgets('a saved language wins over the device language', (
      tester,
    ) async {
      _setDeviceLanguage(tester, 'en');
      await tester.pumpWidget(
        buildApp(
          languageRepository: FakeLanguageRepository(AppLanguage.arabic),
        ),
      );

      expect(find.text('نظرة عامة'), findsOneWidget);
      expect(_direction(tester), TextDirection.rtl);
    });
  });
}
