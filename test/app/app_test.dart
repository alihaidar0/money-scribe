import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/app/theme/app_typography.dart';
import 'package:money_scribe/features/auth/presentation/welcome_screen.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../support/build_app.dart';
import '../support/fake_language_repository.dart';

const _taglineEnglish = 'Your salary, purchases and debts in one place.';
const _taglineArabic = 'راتبك ومشترياتك وديونك في مكان واحد.';

TextDirection _direction(WidgetTester tester) {
  return Directionality.of(tester.element(find.byType(WelcomeScreen)));
}

String? _fontOf(WidgetTester tester, String text) {
  return tester.widget<Text>(find.text(text)).style?.fontFamily;
}

void _setDeviceLanguage(WidgetTester tester, String languageCode) {
  tester.platformDispatcher.localesTestValue = [Locale(languageCode)];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}

void main() {
  testWidgets('a signed-out person starts on the Welcome screen', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(OverviewScreen), findsNothing);
  });

  testWidgets('a signed-in person starts on the Overview', (tester) async {
    await tester.pumpWidget(buildApp(signedIn: true));
    await tester.pumpAndSettle();

    expect(find.byType(OverviewScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
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
      await tester.pumpAndSettle();

      expect(find.text(_taglineArabic), findsOneWidget);
      expect(_direction(tester), TextDirection.rtl);
    });

    testWidgets('shows Arabic in the Arabic font and English in Inter', (
      tester,
    ) async {
      _setDeviceLanguage(tester, 'ar');
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      expect(_fontOf(tester, _taglineArabic), AppTypography.arabicFontFamily);

      _setDeviceLanguage(tester, 'en');
      await tester.pumpAndSettle();
      expect(_fontOf(tester, _taglineEnglish), AppTypography.fontFamily);
    });

    testWidgets('falls back to English on an unsupported device language', (
      tester,
    ) async {
      _setDeviceLanguage(tester, 'fr');
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text(_taglineEnglish), findsOneWidget);
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
      await tester.pumpAndSettle();

      expect(find.text(_taglineArabic), findsOneWidget);
      expect(_direction(tester), TextDirection.rtl);
    });
  });
}
