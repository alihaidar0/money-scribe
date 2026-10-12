import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import 'build_app.dart';
import 'fake_language_repository.dart';
import 'fake_push_messaging_repository.dart';
import 'fake_theme_repository.dart';

/// A tall phone, so a long list fits without scrolling.
const tallPhone = Size(412, 1800);

/// Amounts have a no-break space before the currency symbol.
const nbsp = ' ';

/// Writes an amount the way the app shows it.
String amount(String text) => text.replaceAll(' ₽', '$nbsp₽');

/// The text of an amount exactly as shown.
Finder amountText(String text) => find.text(amount(text));

/// Opens the app signed in with the given demo settings as what its fake
/// server answers, then goes to the tab with the label [english] (or
/// [arabic] in Arabic).
Future<DemoController> openTab(
  WidgetTester tester, {
  required String english,
  required String arabic,
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  Size size = tallPhone,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  final demo = DemoController(initial: settings, latency: Duration.zero);
  await tester.pumpWidget(
    buildApp(
      demo: demo,
      languageRepository: FakeLanguageRepository(language),
      authRepository: FakeAuthRepository(demo: demo, signedIn: true),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byWidgetPredicate(
        (widget) => widget is NavigationBar || widget is NavigationRail,
      ),
      matching: find.text(language == AppLanguage.arabic ? arabic : english),
    ),
  );
  await tester.pumpAndSettle();
  return demo;
}

/// Opens the Transactions tab.
Future<DemoController> openTransactions(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  Size size = tallPhone,
}) {
  return openTab(
    tester,
    english: 'Transactions',
    arabic: 'المعاملات',
    settings: settings,
    language: language,
    size: size,
  );
}

/// Opens the Debts tab.
Future<DemoController> openDebts(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  Size size = tallPhone,
}) {
  return openTab(
    tester,
    english: 'Debts',
    arabic: 'الديون',
    settings: settings,
    language: language,
    size: size,
  );
}

/// Opens the Reports tab.
Future<DemoController> openReports(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  Size size = tallPhone,
}) {
  return openTab(
    tester,
    english: 'Reports',
    arabic: 'التقارير',
    settings: settings,
    language: language,
    size: size,
  );
}

/// Opens the Settings from the gear of the Overview. The push messaging is
/// available and not yet allowed, so every row of the Settings is shown.
Future<DemoController> openSettings(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  Size size = tallPhone,
  FakeThemeRepository? themeRepository,
  FakeLanguageRepository? languageRepository,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  final demo = DemoController(initial: settings, latency: Duration.zero);
  await tester.pumpWidget(
    buildApp(
      demo: demo,
      languageRepository:
          languageRepository ?? FakeLanguageRepository(language),
      themeRepository: themeRepository,
      pushMessaging: FakePushMessagingRepository(),
      authRepository: FakeAuthRepository(demo: demo, signedIn: true),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byTooltip(language == AppLanguage.arabic ? 'الإعدادات' : 'Settings'),
  );
  await tester.pumpAndSettle();
  return demo;
}
