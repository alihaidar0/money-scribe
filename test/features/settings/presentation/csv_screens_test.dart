import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/settings/presentation/csv_import_screen.dart';
import 'package:money_scribe/features/settings/presentation/settings_screen.dart';

import '../../../support/open_screen.dart';

Finder inSheet(Finder finder) =>
    find.descendant(of: find.byType(BottomSheet), matching: finder);

Future<DemoController> openExport(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
}) async {
  final demo = await openSettings(
    tester,
    settings: settings,
    language: language,
  );
  await tester.tap(
    find.text(language == AppLanguage.arabic ? 'تصدير CSV' : 'Export CSV'),
  );
  await tester.pumpAndSettle();
  return demo;
}

Future<DemoController> openImport(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
}) async {
  final demo = await openSettings(
    tester,
    settings: settings,
    language: language,
  );
  await tester.tap(
    find.text(language == AppLanguage.arabic ? 'استيراد CSV' : 'Import CSV'),
  );
  await tester.pumpAndSettle();
  return demo;
}

void main() {
  group('the export sheet (ST-7)', () {
    testWidgets('has the three kinds and the periods, all chosen first', (
      tester,
    ) async {
      await openExport(tester);

      expect(inSheet(find.text('Export CSV')), findsOneWidget);
      expect(inSheet(find.text('What to export')), findsOneWidget);
      for (final kind in ['Transactions', 'Debts', 'Salary months']) {
        final chip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, kind),
        );
        expect(chip.selected, isTrue, reason: kind);
      }
      expect(inSheet(find.text('Period')), findsOneWidget);
      final allTime = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'All time'),
      );
      expect(allTime.selected, isTrue);
      expect(inSheet(find.text('This year')), findsOneWidget);
      expect(inSheet(find.text('Custom')), findsOneWidget);
      expect(inSheet(find.text('Cancel')), findsOneWidget);
      expect(inSheet(find.text('Export')), findsOneWidget);
    });

    testWidgets('unticking every kind turns Export off', (tester) async {
      await openExport(tester);

      for (final kind in ['Transactions', 'Debts', 'Salary months']) {
        await tester.tap(find.widgetWithText(FilterChip, kind));
        await tester.pumpAndSettle();
      }

      expect(find.text('Choose something to export.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Export'))
            .onPressed,
        isNull,
      );
    });

    testWidgets('Custom asks for the first and the last day', (tester) async {
      await openExport(tester);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Export'))
            .onPressed,
        isNull,
      );
    });

    testWidgets('Cancel closes the sheet', (tester) async {
      await openExport(tester);

      await tester.tap(inSheet(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Export closes the sheet and says the file is ready', (
      tester,
    ) async {
      await openExport(tester);

      await tester.tap(inSheet(find.text('Export')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Your CSV file is ready.'), findsOneWidget);
    });

    testWidgets('keeps the sheet and says so when the export fails', (
      tester,
    ) async {
      final demo = await openExport(tester);
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));

      await tester.tap(inSheet(find.text('Export')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.text("Couldn't export. Check your connection."),
        findsOneWidget,
      );
    });

    testWidgets('is in Arabic', (tester) async {
      await openExport(tester, language: AppLanguage.arabic);

      expect(inSheet(find.text('تصدير CSV')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the import screen (ST-8)', () {
    testWidgets('shows the chosen file and that it is ready', (tester) async {
      await openImport(tester);

      expect(find.byType(CsvImportScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Import CSV'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('transactions.csv'), findsOneWidget);
      expect(find.text('42 rows'), findsOneWidget);
      expect(
        find.text('Ready to import: 42 rows, 0 problems.'),
        findsOneWidget,
      );
      expect(find.text('Choose another file'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Import'), findsOneWidget);
    });

    testWidgets('Choose another file shows the next one', (tester) async {
      await openImport(tester);

      await tester.tap(find.text('Choose another file'));
      await tester.pumpAndSettle();

      expect(find.text('debts.csv'), findsOneWidget);
      expect(find.text('12 rows'), findsOneWidget);
    });

    testWidgets('Import shows how many rows were skipped, and why', (
      tester,
    ) async {
      await openImport(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();

      expect(
        find.text('Import finished: 40 imported, 2 skipped.'),
        findsOneWidget,
      );
      expect(find.text('Row 7: the amount is not valid'), findsOneWidget);
      expect(find.text('Row 19: the date is missing'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('a file with no problem skips nothing', (tester) async {
      await openImport(tester);
      await tester.tap(find.text('Choose another file'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();

      expect(
        find.text('Import finished: 12 imported, 0 skipped.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('Done goes back to the Settings', (tester) async {
      await openImport(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('offers Try again with no connection', (tester) async {
      final demo = await openImport(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.noConnection),
      );

      expect(find.text('No connection'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('transactions.csv'), findsOneWidget);
    });

    testWidgets('a failed import is tried again with the same file', (
      tester,
    ) async {
      final demo = await openImport(tester);
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();
      expect(find.text('No connection'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(
        find.text('Import finished: 40 imported, 2 skipped.'),
        findsOneWidget,
      );
    });

    testWidgets('is in Arabic', (tester) async {
      await openImport(tester, language: AppLanguage.arabic);

      expect(find.widgetWithText(AppBar, 'استيراد CSV'), findsOneWidget);
      expect(find.text('transactions.csv'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
