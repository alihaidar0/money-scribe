import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/build_app.dart';
import '../../../support/fake_language_repository.dart';

/// Amounts have a no-break space before the currency symbol.
const nbsp = ' ';

const tallPhone = Size(412, 1800);

/// Writes an amount the way the app shows it.
String amount(String text) => text.replaceAll(' ₽', '$nbsp₽');

Finder amountText(String text) {
  return find.textContaining(amount(text), findRichText: true);
}

/// Opens the app signed in, at the Overview, with the given demo settings as
/// what its fake server answers.
Future<DemoController> pumpApp(
  WidgetTester tester, {
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
  return demo;
}

/// Goes to the Salary tab, then opens the history with the History icon.
Future<DemoController> pumpHistory(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  Size size = tallPhone,
}) async {
  final demo = await pumpApp(
    tester,
    settings: settings,
    language: language,
    size: size,
  );
  await tester.tap(
    find.descendant(
      of: find.byWidgetPredicate(
        (widget) => widget is NavigationBar || widget is NavigationRail,
      ),
      matching: find.text(language == AppLanguage.arabic ? 'الراتب' : 'Salary'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byTooltip(
      language == AppLanguage.arabic ? 'سجل الرواتب' : 'Salary history',
    ),
  );
  await tester.pumpAndSettle();
  return demo;
}
