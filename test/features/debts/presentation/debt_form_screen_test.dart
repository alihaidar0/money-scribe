import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/features/debts/data/fake/fake_debts_repository.dart';
import 'package:money_scribe/features/debts/presentation/debt_details_screen.dart';
import 'package:money_scribe/features/debts/presentation/debt_form_screen.dart';
import 'package:money_scribe/features/debts/presentation/debts_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/open_screen.dart';
import '../../../support/refusing_debts_repository.dart';

/// Opens the form that adds a debt, from the list.
Future<DemoController> openAddForm(
  WidgetTester tester, {
  AppLanguage language = AppLanguage.english,
}) async {
  final demo = await openDebts(tester, language: language);
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  return demo;
}

/// Opens the form that changes the debt of Sam.
Future<DemoController> openEditForm(WidgetTester tester) async {
  final demo = await openDebts(tester);
  await tester.tap(find.text('Sam'));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit'));
  await tester.pumpAndSettle();
  return demo;
}

Finder saveButton() => find.widgetWithText(FilledButton, 'Save');
Finder saveChangesButton() => find.widgetWithText(FilledButton, 'Save changes');

bool isEnabled(WidgetTester tester, Finder button) {
  return tester.widget<FilledButton>(button).onPressed != null;
}

/// The person, amount and note fields, in the order they are on the form.
Finder field(int index) => find.byType(TextField).at(index);

void main() {
  group('a new debt (DB-2)', () {
    testWidgets('has the title, the back arrow and no navigation bar', (
      tester,
    ) async {
      await openAddForm(tester);

      expect(find.byType(DebtFormScreen), findsOneWidget);
      expect(find.text('Add debt'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('has the fields in order, starting today as money lent', (
      tester,
    ) async {
      await openAddForm(tester);

      final labels = [
        'Person',
        'Amount',
        'Start date',
        'Due date (optional)',
        'Note',
      ];
      var previous = -1.0;
      for (final label in labels) {
        final top = tester.getTopLeft(find.text(label)).dy;
        expect(top, greaterThan(previous), reason: label);
        previous = top;
      }
      expect(find.text('I lent'), findsOneWidget);
      expect(find.text('I borrowed'), findsOneWidget);
      expect(
        tester
            .widget<PillSegmentedButton<DebtDirection>>(
              find.byType(PillSegmentedButton<DebtDirection>),
            )
            .selected,
        {DebtDirection.lent},
      );
      expect(find.text('11 Oct'), findsOneWidget);
    });

    testWidgets('Save waits for a person and an amount above zero', (
      tester,
    ) async {
      await openAddForm(tester);
      expect(isEnabled(tester, saveButton()), isFalse);

      await tester.enterText(field(0), 'Lee');
      await tester.pumpAndSettle();
      expect(isEnabled(tester, saveButton()), isFalse);

      await tester.enterText(field(1), '0');
      await tester.pumpAndSettle();
      expect(isEnabled(tester, saveButton()), isFalse);
      expect(find.text('Enter an amount above zero.'), findsOneWidget);

      await tester.enterText(field(1), '1500');
      await tester.pumpAndSettle();
      expect(isEnabled(tester, saveButton()), isTrue);
    });

    testWidgets('Save adds it and goes back to the list', (tester) async {
      await openAddForm(tester);
      await tester.enterText(field(0), 'Lee');
      await tester.enterText(field(1), '1500.50');
      await tester.tap(find.text('I borrowed'));
      await tester.enterText(field(2), 'Bike');
      await tester.pumpAndSettle();

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.byType(DebtsScreen), findsOneWidget);
      expect(find.text('Lee'), findsOneWidget);
      expect(
        find.text(amount('Borrowed 1,500.50 ₽ · repaid 0.00 ₽')),
        findsOneWidget,
      );
      // It is borrowed, so it adds to what the person owes.
      expect(amountText('1,500.50 ₽'), findsWidgets);
    });

    testWidgets('the due day is optional and can be set and cleared', (
      tester,
    ) async {
      await openAddForm(tester);

      await tester.tap(find.text('Due date (optional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('20 Oct'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear date'));
      await tester.pumpAndSettle();
      expect(find.text('20 Oct'), findsNothing);
    });

    testWidgets('a due day before the start day is an error', (tester) async {
      await openAddForm(tester);
      await tester.enterText(field(0), 'Lee');
      await tester.enterText(field(1), '100');

      await tester.tap(find.text('Due date (optional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(
        find.text("The due date can't be before the start date."),
        findsOneWidget,
      );
      expect(isEnabled(tester, saveButton()), isFalse);
    });

    testWidgets('a failed save keeps the form and offers Retry (ERR-1)', (
      tester,
    ) async {
      final demo = await openAddForm(tester);
      await tester.enterText(field(0), 'Lee');
      await tester.enterText(field(1), '100');
      await tester.pumpAndSettle();
      demo.update(const DemoSettings(save: DemoSave.fails));

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.byType(DebtFormScreen), findsOneWidget);
      expect(find.text("Couldn't save. Check your connection."), findsOne);
      // The message sits above the Save button, which stays in sight.
      expect(
        tester.getRect(find.byType(SnackBar)).bottom,
        lessThanOrEqualTo(tester.getRect(saveButton()).top),
      );

      demo.update(const DemoSettings());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(DebtsScreen), findsOneWidget);
      expect(find.text('Lee'), findsOneWidget);
    });
  });

  group('changing a debt (DB-8)', () {
    testWidgets('is filled in, with Save changes', (tester) async {
      await openEditForm(tester);

      expect(find.text('Edit debt'), findsOneWidget);
      expect(tester.widget<TextField>(field(0)).controller?.text, 'Sam');
      expect(tester.widget<TextField>(field(1)).controller?.text, '10,000.00');
      expect(
        tester.widget<TextField>(field(2)).controller?.text,
        'Lunch money',
      );
      expect(find.text('1 Oct'), findsOneWidget);
      expect(find.text('31 Oct'), findsOneWidget);
      expect(
        tester
            .widget<PillSegmentedButton<DebtDirection>>(
              find.byType(PillSegmentedButton<DebtDirection>),
            )
            .selected,
        {DebtDirection.lent},
      );
      expect(find.text('Save'), findsNothing);
      expect(saveChangesButton(), findsOneWidget);
    });

    testWidgets('Save changes waits for a change', (tester) async {
      await openEditForm(tester);
      expect(isEnabled(tester, saveChangesButton()), isFalse);

      await tester.enterText(field(2), 'Dinner');
      await tester.pumpAndSettle();

      expect(isEnabled(tester, saveChangesButton()), isTrue);
    });

    testWidgets('the amount cannot be less than what was repaid', (
      tester,
    ) async {
      await openEditForm(tester);

      await tester.enterText(field(1), '3000');
      await tester.pumpAndSettle();

      expect(
        find.text(
          amount(
            "The amount can't be less than the 4,000.00 ₽ already repaid.",
          ),
        ),
        findsOneWidget,
      );
      expect(isEnabled(tester, saveChangesButton()), isFalse);

      await tester.enterText(field(1), '4000');
      await tester.pumpAndSettle();
      expect(isEnabled(tester, saveChangesButton()), isTrue);
    });

    testWidgets('Save changes keeps them and goes back to the debt', (
      tester,
    ) async {
      await openEditForm(tester);
      await tester.enterText(field(1), '12000');
      await tester.pumpAndSettle();

      await tester.tap(saveChangesButton());
      await tester.pumpAndSettle();

      expect(find.byType(DebtDetailsScreen), findsOneWidget);
      expect(find.text(amount('Lent 12,000.00 ₽')), findsOneWidget);
      expect(amountText('8,000.00 ₽'), findsOneWidget);
    });
  });

  group('leaving with changes', () {
    testWidgets('no change leaves at once', (tester) async {
      await openAddForm(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(DebtsScreen), findsOneWidget);
    });

    testWidgets('a change asks first, and Keep editing stays', (tester) async {
      await openAddForm(tester);
      await tester.enterText(field(0), 'Lee');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('Your changes have not been saved.'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.byType(DebtFormScreen), findsOneWidget);
    });

    testWidgets('Discard leaves and drops the changes', (tester) async {
      await openAddForm(tester);
      await tester.enterText(field(0), 'Lee');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.byType(DebtsScreen), findsOneWidget);
      expect(find.text('Lee'), findsNothing);
    });
  });

  group('in Arabic', () {
    testWidgets('shows Arabic labels and Western digits', (tester) async {
      await openAddForm(tester, language: AppLanguage.arabic);

      expect(find.text('إضافة دين'), findsOneWidget);
      expect(find.text('أقرضت'), findsOneWidget);
      expect(find.text('اقترضت'), findsOneWidget);
      expect(find.text('الشخص'), findsOneWidget);
      expect(find.text('تاريخ الاستحقاق (اختياري)'), findsOneWidget);
      expect(find.text('حفظ'), findsOneWidget);
      expect(find.textContaining(RegExp('[٠-٩]')), findsNothing);
    });
  });

  group('what the server says to Save', () {
    testWidgets('a refusal for too many debts says so and keeps the form', (
      tester,
    ) async {
      await openDebts(
        tester,
        debtsRepository: (demo) => FakeDebtsRepository(demo: demo, maxDebts: 3),
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(field(0), 'Lee');
      await tester.enterText(field(1), '1500');
      await tester.pumpAndSettle();

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'You have the most debts allowed. Delete one to add another.',
        ),
        findsOneWidget,
      );
      expect(find.byType(DebtFormScreen), findsOneWidget);
      expect(find.text('Lee'), findsOneWidget);
    });

    testWidgets('a debt changed on another device is loaded again', (
      tester,
    ) async {
      late RefusingDebtsRepository repository;
      await openDebts(
        tester,
        debtsRepository: (demo) =>
            repository = RefusingDebtsRepository(demo: demo),
      );
      await tester.tap(find.text('Sam'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(field(2), 'Dinner');
      await tester.pumpAndSettle();
      repository.failure = const StaleRecordException();

      await tester.tap(saveChangesButton());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'This debt was changed on another device. It has been loaded again.',
        ),
        findsOneWidget,
      );
      expect(find.byType(DebtFormScreen), findsOneWidget);
    });
  });

  group('the currency of a new debt', () {
    testWidgets('is the default currency of the account', (tester) async {
      await openDebts(
        tester,
        debtsRepository: (demo) => FakeDebtsRepository(
          demo: demo,
          defaultCurrency: () async => Currency.usd,
        ),
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(field(1), '1500');
      await tester.pumpAndSettle();

      expect(find.text(r'$'), findsOneWidget);
      expect(find.text('₽'), findsNothing);
    });
  });
}
