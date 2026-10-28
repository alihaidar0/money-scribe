import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/salary/domain/fixed_items_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/build_app.dart';
import '../../../support/fake_language_repository.dart';
import '../../../support/navigation_tab.dart';

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
  SalaryRepository? salaryRepository,
  FixedItemsRepository? fixedItemsRepository,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  final demo = DemoController(initial: settings, latency: Duration.zero);
  await tester.pumpWidget(
    buildApp(
      demo: demo,
      salaryRepository: salaryRepository,
      fixedItemsRepository: fixedItemsRepository,
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
    navigationTab(language == AppLanguage.arabic ? 'الراتب' : 'Salary'),
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

/// Opens the salary history, then the comparison with the Compare icon.
Future<DemoController> pumpCompare(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  Size size = tallPhone,
}) async {
  final demo = await pumpHistory(
    tester,
    settings: settings,
    language: language,
    size: size,
  );
  await tester.tap(
    find.byTooltip(
      language == AppLanguage.arabic ? 'مقارنة الأشهر' : 'Compare months',
    ),
  );
  await tester.pumpAndSettle();
  return demo;
}

/// Goes to the Salary tab, then opens the "Fixed items" segment.
Future<DemoController> pumpFixedItems(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  Size size = tallPhone,
  SalaryRepository? salaryRepository,
  FixedItemsRepository? fixedItemsRepository,
}) async {
  final demo = await pumpApp(
    tester,
    settings: settings,
    language: language,
    size: size,
    salaryRepository: salaryRepository,
    fixedItemsRepository: fixedItemsRepository,
  );
  final arabic = language == AppLanguage.arabic;
  await tester.tap(navigationTab(arabic ? 'الراتب' : 'Salary'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(arabic ? 'البنود الثابتة' : 'Fixed items'));
  await tester.pumpAndSettle();
  return demo;
}
