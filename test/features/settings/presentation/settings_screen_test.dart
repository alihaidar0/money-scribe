import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/settings/presentation/settings_screen.dart';

import '../../../support/build_app.dart';
import '../../../support/fake_language_repository.dart';

AppLanguage _selectedLanguage(WidgetTester tester) {
  return tester
      .widget<RadioGroup<AppLanguage>>(find.byType(RadioGroup<AppLanguage>))
      .groupValue!;
}

TextDirection _direction(WidgetTester tester) {
  return Directionality.of(tester.element(find.byType(SettingsScreen)));
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the Overview screen opens the Settings screen', (tester) async {
    await tester.pumpWidget(buildApp());
    await _openSettings(tester);

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
  });

  testWidgets('it offers the system language, English and Arabic', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await _openSettings(tester);

    expect(find.text('System default'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(_selectedLanguage(tester), AppLanguage.system);
  });

  testWidgets('choosing Arabic switches the app to Arabic, right to left, '
      'and saves the choice', (tester) async {
    final repository = FakeLanguageRepository();
    await tester.pumpWidget(buildApp(languageRepository: repository));
    await _openSettings(tester);
    expect(_direction(tester), TextDirection.ltr);

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('اللغة'), findsOneWidget);
    expect(_direction(tester), TextDirection.rtl);
    expect(_selectedLanguage(tester), AppLanguage.arabic);
    expect(repository.language, AppLanguage.arabic);
  });

  testWidgets('choosing the system language returns to the device language', (
    tester,
  ) async {
    final repository = FakeLanguageRepository(AppLanguage.arabic);
    await tester.pumpWidget(buildApp(languageRepository: repository));
    await tester.tap(find.byTooltip('الإعدادات'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('لغة النظام'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(_direction(tester), TextDirection.ltr);
    expect(repository.language, AppLanguage.system);
  });
}
