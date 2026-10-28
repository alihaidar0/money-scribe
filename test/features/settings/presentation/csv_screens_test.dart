import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/app/shell/floating_navigation_bar.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/settings/data/fake/fake_csv_transfer_repository.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';
import 'package:money_scribe/features/settings/presentation/csv_import_screen.dart';
import 'package:money_scribe/features/settings/presentation/settings_screen.dart';

import '../../../support/open_screen.dart';

/// A picker that offers a file with a day of more rows than one call takes.
class _CrowdedFile extends FakeCsvTransferRepository {
  new({required super.demo});

  @override
  Future<CsvFile?> chooseFile() async {
    return CsvFile(
      name: 'transactions.csv',
      parts: [
        CsvFilePart(
          kind: CsvDataKind.transactions,
          records: [
            for (var row = 2; row < 504; row++)
              CsvRecord(row: row, day: '2026-10-24', cells: const {}),
          ],
        ),
      ],
    );
  }
}

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
      for (final kind in [
        'Accounts and categories',
        'Transactions',
        'Debts',
        'Salary months',
      ]) {
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

      for (final kind in [
        'Accounts and categories',
        'Transactions',
        'Debts',
        'Salary months',
      ]) {
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

    testWidgets('one chip stands for the accounts and the categories', (
      tester,
    ) async {
      await openExport(tester);

      await tester.tap(
        find.widgetWithText(FilterChip, 'Accounts and categories'),
      );
      await tester.pumpAndSettle();
      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Accounts and categories'),
      );

      expect(chip.selected, isFalse);
      expect(
        inSheet(
          find.text('The period does not apply to accounts and categories.'),
        ),
        findsNothing,
      );

      await tester.tap(
        find.widgetWithText(FilterChip, 'Accounts and categories'),
      );
      await tester.pumpAndSettle();

      expect(
        inSheet(
          find.text('The period does not apply to accounts and categories.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('says several kinds go in one .zip file', (tester) async {
      await openExport(tester);

      expect(
        inSheet(
          find.text('Several kinds are saved together in one .zip file.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Export closes the sheet and asks for the password', (
      tester,
    ) async {
      await openExport(tester);

      await tester.tap(inSheet(find.text('Export')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Confirm your password'), findsOneWidget);
      expect(
        find.text(
          'We ask for your password before exporting your data. We will also '
          'send you an email to say an export was made.',
        ),
        findsOneWidget,
      );
    });
  });

  group('the password dialog (ST-7b, ST-7c)', () {
    Future<DemoController> openDialog(
      WidgetTester tester, {
      DemoSettings settings = const DemoSettings(),
    }) async {
      final demo = await openExport(tester, settings: settings);
      await tester.tap(inSheet(find.text('Export')));
      await tester.pumpAndSettle();
      return demo;
    }

    Finder exportButton() => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    );

    testWidgets('Export waits for a password', (tester) async {
      await openDialog(tester);

      expect(tester.widget<FilledButton>(exportButton()).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'secret');
      await tester.pump();

      expect(tester.widget<FilledButton>(exportButton()).onPressed, isNotNull);
    });

    testWidgets('the password makes the file and says it is ready', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.enterText(find.byType(TextField), 'secret');
      await tester.pump();
      await tester.tap(exportButton());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Your CSV file is ready.'), findsOneWidget);
    });

    testWidgets('a wrong password is said under the field', (tester) async {
      await openDialog(
        tester,
        settings: const DemoSettings(signIn: DemoSignIn.wrongPassword),
      );

      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.pump();
      await tester.tap(exportButton());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('The password is incorrect.'), findsOneWidget);
    });

    testWidgets('too many attempts lock the field and the button', (
      tester,
    ) async {
      await openDialog(
        tester,
        settings: const DemoSettings(passwordChange: DemoPasswordChange.locked),
      );

      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.pump();
      await tester.tap(exportButton());
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Too many attempts. Try again in 15:00.'),
        findsOneWidget,
      );
      expect(find.text('Try again in 15:00'), findsOneWidget);
      expect(tester.widget<FilledButton>(exportButton()).onPressed, isNull);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('no connection is said, and the dialog stays', (tester) async {
      final demo = await openDialog(tester);
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));

      await tester.enterText(find.byType(TextField), 'secret');
      await tester.pump();
      await tester.tap(exportButton());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text("Couldn't export. Check your connection."),
        findsOneWidget,
      );
    });

    testWidgets('Cancel closes it with nothing exported', (tester) async {
      await openDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Your CSV file is ready.'), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  testWidgets('the export sheet is in Arabic', (tester) async {
    await openExport(tester, language: AppLanguage.arabic);

    expect(inSheet(find.text('تصدير CSV')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('the import screen (ST-8)', () {
    testWidgets('shows the chosen file and that it is ready', (tester) async {
      await openImport(tester);

      expect(find.byType(CsvImportScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Import CSV'), findsOneWidget);
      expect(find.byType(FloatingNavigationBar), findsNothing);
      expect(find.text('transactions.csv'), findsOneWidget);
      expect(find.text('42 rows'), findsOneWidget);
      expect(
        find.text('Estimate: 42 rows can be imported, 0 problems found.'),
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

    testWidgets('warns about a day with more rows than one call takes', (
      tester,
    ) async {
      await openSettings(
        tester,
        csvTransferRepository: (demo) => _CrowdedFile(demo: demo),
      );
      await tester.tap(find.text('Import CSV'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          '1 day has more than 500 rows. Rows that repeat inside such a day '
          'may be imported twice.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('says nothing about days when no day is crowded', (
      tester,
    ) async {
      await openImport(tester);

      expect(find.textContaining('more than 500 rows'), findsNothing);
    });

    testWidgets('a file that is not an export says why, before sending', (
      tester,
    ) async {
      await openImport(tester);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Choose another file'));
        await tester.pumpAndSettle();
      }

      expect(find.text("This file can't be imported"), findsOneWidget);
      expect(
        find.text(
          'Its first row does not have the columns of a Money Scribe export.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Import'), findsNothing);

      await tester.tap(find.text('Choose another file'));
      await tester.pumpAndSettle();

      expect(find.text('transactions.csv'), findsOneWidget);
    });

    testWidgets('an export of several kinds names the kind of each row', (
      tester,
    ) async {
      await openImport(tester);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Choose another file'));
        await tester.pumpAndSettle();
      }

      expect(find.text('money-scribe-export.zip'), findsOneWidget);
      expect(find.text('25 rows'), findsOneWidget);
      expect(
        find.text('Estimate: 25 rows can be imported, 0 problems found.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();

      expect(
        find.text('Import finished: 23 imported, 2 skipped.'),
        findsOneWidget,
      );
      expect(find.text('Accounts, row 3: already exists'), findsOneWidget);
      expect(
        find.text('Categories, row 2: the name is used by a built-in category'),
        findsOneWidget,
      );
    });

    testWidgets('Import shows how many rows were skipped, and why', (
      tester,
    ) async {
      await openImport(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();

      expect(
        find.text('Import finished: 38 imported, 4 skipped.'),
        findsOneWidget,
      );
      expect(find.text('Row 7: the amount is not valid'), findsOneWidget);
      expect(find.text('Row 19: the date is missing'), findsOneWidget);
      expect(find.text('Row 23: already exists'), findsOneWidget);
      expect(find.text('Row 31: the account does not exist'), findsOneWidget);
      expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
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
      expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
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
        find.text('Import finished: 38 imported, 4 skipped.'),
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
