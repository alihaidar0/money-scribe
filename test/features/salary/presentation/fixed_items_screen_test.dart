import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/features/salary/data/fake/fake_fixed_items_repository.dart';
import 'package:money_scribe/features/salary/data/fake/fake_salary_repository.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/salary_figures.dart';
import 'package:money_scribe/features/salary/presentation/fixed_items_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_history_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/fake_server_salary_repository.dart';
import 'salary_test_helpers.dart';

const twoPayments = DemoSettings(paymentMode: PaymentMode.twoPayments);

const october = YearMonth(2026, 10);

const copyLabel = 'Copy from last month';

/// A row's amount as shown, with a true minus sign for an expense.
Finder figure(String text) => find.text(amount(text));

/// The line under the balance that says how it adds up. It only breaks
/// between terms, so its spaces are no-break ones; [text] is written with
/// plain spaces.
Finder sumLine(String text) {
  String plain(String value) => value.replaceAll('\u00a0', ' ');

  return find.byWidgetPredicate(
    (widget) => widget is Text && plain(widget.data ?? '') == plain(text),
  );
}

Finder inSheet(Finder finder) {
  return find.descendant(of: find.byType(BottomSheet), matching: finder);
}

/// The page's segmented control of the parts, not the one in the sheet.
Finder pageParts() {
  return find.descendant(
    of: find.byType(Scaffold).first,
    matching: find.byType(PillSegmentedButton<FixedItemPart>),
  );
}

Future<void> choosePart(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: pageParts().first, matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> openAddSheet(WidgetTester tester) async {
  await tester.tap(find.text('Add item'));
  await tester.pumpAndSettle();
}

Future<void> openEditSheet(WidgetTester tester, String name) async {
  await tester.tap(find.byTooltip('Edit $name'));
  await tester.pumpAndSettle();
}

/// Types into the name and amount fields of the sheet.
Future<void> fillSheet(
  WidgetTester tester, {
  String? name,
  String? amount,
}) async {
  final fields = inSheet(find.byType(TextField));
  if (name != null) await tester.enterText(fields.at(0), name);
  if (amount != null) await tester.enterText(fields.at(1), amount);
  await tester.pumpAndSettle();
}

Finder saveButton() => inSheet(find.widgetWithText(FilledButton, 'Save'));

/// The repository of a saved month whose items were all deleted.
Future<FakeFixedItemsRepository> withoutItems() async {
  final demo = DemoController(latency: Duration.zero);
  final repository = FakeFixedItemsRepository(
    demo: demo,
    salary: FakeSalaryRepository(demo: demo),
  );
  for (final item in await repository.items(october)) {
    await repository.delete(october, item.id, version: item.version);
  }
  return repository;
}

void main() {
  group('one payment (FIX-1)', () {
    testWidgets('is the second segment of the Salary tab', (tester) async {
      await pumpFixedItems(tester);

      expect(find.byType(FixedItemsScreen), findsOneWidget);
      expect(find.text('Salary'), findsWidgets);
      expect(find.byTooltip('Salary history'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      final segments = find.byType(PillSegmentedButton<Object?>);
      expect(segments, findsNothing);
    });

    testWidgets('lists the items with their sign and an edit button', (
      tester,
    ) async {
      await pumpFixedItems(tester);

      expect(find.text('Scholarship'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Services'), findsOneWidget);
      expect(figure('+5,000.00 ₽'), findsOneWidget);
      expect(figure('−30,000.00 ₽'), findsOneWidget);
      expect(figure('−4,500.00 ₽'), findsOneWidget);
      for (final name in ['Scholarship', 'Rent', 'Services']) {
        expect(find.byTooltip('Edit $name'), findsOneWidget);
      }
      // An arrow in for income and out for an expense: not colour alone.
      expect(find.byIcon(Icons.south_west), findsOneWidget);
      expect(find.byIcon(Icons.north_east), findsNWidgets(2));
    });

    testWidgets('shows the balance after the items and how it adds up', (
      tester,
    ) async {
      await pumpFixedItems(tester);

      expect(find.text('Balance after fixed items'), findsOneWidget);
      expect(figure('74,900.00 ₽'), findsOneWidget);
      expect(
        sumLine(
          'Salary 104,400.00 ₽ + Scholarship 5,000.00 ₽ '
          '− Rent 30,000.00 ₽ − Services 4,500.00 ₽',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Whole month'), findsNothing);
    });

    testWidgets('has the Add item button and no choice of part', (
      tester,
    ) async {
      await pumpFixedItems(tester);

      expect(find.widgetWithText(FloatingActionButton, 'Add item'), findsOne);
      expect(pageParts(), findsNothing);
    });

    testWidgets('the Month segment goes back to the salary of the month', (
      tester,
    ) async {
      await pumpFixedItems(tester);

      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryScreen), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('the History icon opens the saved months', (tester) async {
      await pumpFixedItems(tester);

      await tester.tap(find.byTooltip('Salary history'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryHistoryScreen), findsOneWidget);
    });
  });

  group('two payments (FIX-2)', () {
    testWidgets('has the choice Part 1 and Part 2, starting with Part 1', (
      tester,
    ) async {
      await pumpFixedItems(tester, settings: twoPayments);

      expect(pageParts(), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Scholarship'), findsNothing);
    });

    testWidgets('shows the balance of Part 1 and of the whole month', (
      tester,
    ) async {
      await pumpFixedItems(tester, settings: twoPayments);

      expect(find.text('Balance after fixed items · Part 1'), findsOneWidget);
      expect(figure('9,000.00 ₽'), findsOneWidget);
      expect(
        sumLine('Pay 43,500.00 ₽ − Rent 30,000.00 ₽ − Services 4,500.00 ₽'),
        findsOneWidget,
      );
      expect(figure('Whole month 74,900.00 ₽'), findsOneWidget);
    });

    testWidgets('Part 2 shows its own items and balance', (tester) async {
      await pumpFixedItems(tester, settings: twoPayments);

      await choosePart(tester, 'Part 2');

      expect(find.text('Scholarship'), findsOneWidget);
      expect(find.text('Rent'), findsNothing);
      expect(find.text('Balance after fixed items · Part 2'), findsOneWidget);
      expect(figure('65,900.00 ₽'), findsOneWidget);
      expect(sumLine('Pay 60,900.00 ₽ + Scholarship 5,000.00 ₽'), findsOne);
      expect(figure('Whole month 74,900.00 ₽'), findsOneWidget);
    });
  });

  group('adding an item (FIX-3)', () {
    testWidgets('opens a sheet with a name, an amount and Income | Expense', (
      tester,
    ) async {
      await pumpFixedItems(tester);

      await openAddSheet(tester);

      expect(find.text('Add fixed item'), findsOneWidget);
      expect(inSheet(find.byType(TextField)), findsNWidgets(2));
      expect(inSheet(find.text('Name')), findsOneWidget);
      expect(inSheet(find.text('Amount')), findsOneWidget);
      expect(inSheet(find.text('Income')), findsOneWidget);
      expect(inSheet(find.text('Expense')), findsOneWidget);
      expect(inSheet(find.text('Cancel')), findsOneWidget);
      expect(saveButton(), findsOneWidget);
      // Nothing to delete, and a month with one payment has no parts.
      expect(inSheet(find.text('Delete')), findsNothing);
      expect(find.text('Day of the month'), findsNothing);
    });

    testWidgets('Save waits for a name and an amount above zero', (
      tester,
    ) async {
      await pumpFixedItems(tester);
      await openAddSheet(tester);
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);

      await fillSheet(tester, name: 'Gym');
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);

      await fillSheet(tester, amount: '0');
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);

      await fillSheet(tester, amount: '1200');
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);

      await fillSheet(tester, name: '   ');
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);
    });

    testWidgets('Save adds the item and counts it in the balance', (
      tester,
    ) async {
      await pumpFixedItems(tester);
      await openAddSheet(tester);

      await fillSheet(tester, name: 'Gym', amount: '1200.50');
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Gym'), findsOneWidget);
      // New items are expenses until Income is chosen.
      expect(figure('−1,200.50 ₽'), findsOneWidget);
      expect(figure('73,699.50 ₽'), findsOneWidget);
    });

    testWidgets('Income adds to the balance', (tester) async {
      await pumpFixedItems(tester);
      await openAddSheet(tester);

      await fillSheet(tester, name: 'Gift', amount: '1000');
      await tester.tap(inSheet(find.text('Income')));
      await tester.pumpAndSettle();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(figure('+1,000.00 ₽'), findsOneWidget);
      expect(figure('75,900.00 ₽'), findsOneWidget);
    });

    testWidgets('Cancel and a tap outside close it without adding', (
      tester,
    ) async {
      await pumpFixedItems(tester);
      await openAddSheet(tester);
      await fillSheet(tester, name: 'Gym', amount: '1200');

      await tester.tap(inSheet(find.text('Cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);

      await openAddSheet(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Gym'), findsNothing);
    });

    testWidgets('in two payments it asks the day, starting in the shown part', (
      tester,
    ) async {
      await pumpFixedItems(tester, settings: twoPayments);
      await choosePart(tester, 'Part 2');

      await openAddSheet(tester);

      expect(find.text('Day of the month'), findsOneWidget);
      expect(inSheet(find.text('16')), findsOneWidget);
      expect(inSheet(find.text('Part 2')), findsOneWidget);
    });

    testWidgets('an item added to Part 1 does not appear in Part 2', (
      tester,
    ) async {
      await pumpFixedItems(tester, settings: twoPayments);
      await openAddSheet(tester);

      await fillSheet(tester, name: 'Gym', amount: '1200');
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.text('Gym'), findsOneWidget);
      expect(figure('7,800.00 ₽'), findsOneWidget);

      await choosePart(tester, 'Part 2');
      expect(find.text('Gym'), findsNothing);
      expect(figure('65,900.00 ₽'), findsOneWidget);
    });
  });

  group('changing an item (FIX-4)', () {
    testWidgets('opens the sheet filled in, with Delete', (tester) async {
      await pumpFixedItems(tester);

      await openEditSheet(tester, 'Rent');

      expect(find.text('Edit fixed item'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(inSheet(find.byType(TextField)).at(0))
            .controller
            ?.text,
        'Rent',
      );
      expect(
        tester
            .widget<TextField>(inSheet(find.byType(TextField)).at(1))
            .controller
            ?.text,
        '30,000.00',
      );
      expect(inSheet(find.text('Delete')), findsOneWidget);
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
    });

    testWidgets('shows its day and the part it falls in, in two payments', (
      tester,
    ) async {
      await pumpFixedItems(tester, settings: twoPayments);

      await openEditSheet(tester, 'Rent');

      expect(find.text('Day of the month'), findsOneWidget);
      expect(inSheet(find.text('1')), findsOneWidget);
      expect(inSheet(find.text('Part 1')), findsOneWidget);
      expect(
        tester
            .widget<PillSegmentedButton<FixedItemKind>>(
              inSheet(find.byType(PillSegmentedButton<FixedItemKind>)),
            )
            .selected,
        {FixedItemKind.expense},
      );
    });

    testWidgets('Save keeps the changes', (tester) async {
      await pumpFixedItems(tester);
      await openEditSheet(tester, 'Rent');

      await fillSheet(tester, name: 'Flat', amount: '31000');
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.text('Rent'), findsNothing);
      expect(find.text('Flat'), findsOneWidget);
      expect(figure('−31,000.00 ₽'), findsOneWidget);
      expect(figure('73,900.00 ₽'), findsOneWidget);
    });

    testWidgets('saving it unchanged changes nothing', (tester) async {
      await pumpFixedItems(tester);
      await openEditSheet(tester, 'Rent');

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(figure('−30,000.00 ₽'), findsOneWidget);
      expect(figure('74,900.00 ₽'), findsOneWidget);
    });

    testWidgets('dating an item in the 16th or later moves it to Part 2', (
      tester,
    ) async {
      await pumpFixedItems(tester, settings: twoPayments);
      await openEditSheet(tester, 'Services');

      // Services falls on the 10th; the 16th is the first day of Part 2.
      for (var day = 10; day < 16; day++) {
        await tester.tap(inSheet(find.byTooltip('Increase')));
        await tester.pump();
      }
      expect(inSheet(find.text('Part 2')), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.text('Services'), findsNothing);
      expect(figure('13,500.00 ₽'), findsOneWidget);
      await choosePart(tester, 'Part 2');
      expect(find.text('Services'), findsOneWidget);
    });

    testWidgets('Cancel leaves the item as it was', (tester) async {
      await pumpFixedItems(tester);
      await openEditSheet(tester, 'Rent');
      await fillSheet(tester, name: 'Flat');

      await tester.tap(inSheet(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Flat'), findsNothing);
    });
  });

  group('deleting an item (FIX-5)', () {
    testWidgets('Delete asks first, with the name of the item', (tester) async {
      await pumpFixedItems(tester);
      await openEditSheet(tester, 'Rent');

      await tester.tap(inSheet(find.text('Delete')));
      await tester.pumpAndSettle();

      expect(find.text('Delete fixed item?'), findsOneWidget);
      expect(
        find.text(
          'Rent will be removed from your fixed items. This cannot be undone.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Cancel'), findsWidgets);
      expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);
    });

    testWidgets('Cancel goes back to the sheet and keeps the item', (
      tester,
    ) async {
      await pumpFixedItems(tester);
      await openEditSheet(tester, 'Rent');
      await tester.tap(inSheet(find.text('Delete')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel').last);
      await tester.pumpAndSettle();

      expect(find.text('Delete fixed item?'), findsNothing);
      expect(find.text('Edit fixed item'), findsOneWidget);
      expect(find.text('Rent'), findsWidgets);
    });

    testWidgets('Delete removes the item and counts it out of the balance', (
      tester,
    ) async {
      await pumpFixedItems(tester);
      await openEditSheet(tester, 'Rent');
      await tester.tap(inSheet(find.text('Delete')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Rent'), findsNothing);
      expect(figure('104,900.00 ₽'), findsOneWidget);
    });
  });

  group('no fixed items (FIX-6)', () {
    testWidgets('says so and offers Add item', (tester) async {
      await pumpFixedItems(tester, fixedItemsRepository: await withoutItems());

      expect(find.text('No fixed items yet'), findsOneWidget);
      expect(find.text('Add your rent, services or scholarship.'), findsOne);
      expect(find.widgetWithText(FilledButton, 'Add item'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Balance after fixed items'), findsNothing);
      // The segments and the navigation bar stay.
      expect(find.text('Month'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Add item adds the first one', (tester) async {
      await pumpFixedItems(tester, fixedItemsRepository: await withoutItems());
      await tester.tap(find.widgetWithText(FilledButton, 'Add item'));
      await tester.pumpAndSettle();
      expect(find.text('Add fixed item'), findsOneWidget);

      await fillSheet(tester, name: 'Gym', amount: '1200');
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.text('No fixed items yet'), findsNothing);
      expect(find.text('Gym'), findsOneWidget);
    });

    testWidgets('deleting the last item shows it', (tester) async {
      await pumpFixedItems(tester, settings: twoPayments);
      await choosePart(tester, 'Part 2');
      await openEditSheet(tester, 'Scholarship');
      await tester.tap(inSheet(find.text('Delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // Part 2 is empty; Part 1 still has its items.
      expect(find.text('No fixed items yet'), findsOneWidget);
      await choosePart(tester, 'Part 1');
      expect(find.text('Rent'), findsOneWidget);
    });
  });

  group('copy from last month', () {
    Finder copyButton() => find.widgetWithText(TextButton, copyLabel);

    Finder confirmButton() => find.widgetWithText(FilledButton, 'Copy');

    Future<void> openAugust(WidgetTester tester) async {
      await pumpApp(tester);
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/salary/fixed-items?month=2026-08');
      await tester.pumpAndSettle();
    }

    testWidgets('asks before adding to a month that has items', (tester) async {
      await pumpFixedItems(tester);
      expect(find.text('Rent'), findsOneWidget);

      await tester.tap(copyButton());
      await tester.pumpAndSettle();

      expect(find.text('Copy from last month?'), findsOneWidget);
      expect(
        find.text(
          "This month already has fixed items. Last month's items will be "
          'added to them.',
        ),
        findsOneWidget,
      );
      // Nothing is copied until the person says so.
      expect(find.text('Rent'), findsOneWidget);
    });

    testWidgets('Cancel copies nothing', (tester) async {
      await pumpFixedItems(tester);
      await tester.tap(copyButton());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Copy from last month?'), findsNothing);
      expect(find.text('Rent'), findsOneWidget);
    });

    testWidgets("Copy adds last month's items to the list and the balance", (
      tester,
    ) async {
      await pumpFixedItems(tester);
      expect(figure('74,900.00 ₽'), findsOneWidget);
      await tester.tap(copyButton());
      await tester.pumpAndSettle();

      await tester.tap(confirmButton());
      await tester.pumpAndSettle();

      expect(find.text('Copy from last month?'), findsNothing);
      expect(find.text('Rent'), findsNWidgets(2));
      expect(find.text('Scholarship'), findsNWidgets(2));
      // The salary of 104,400.00 ₽ and twice the items: +10,000.00 ₽ income
      // and 69,000.00 ₽ of costs.
      expect(figure('45,400.00 ₽'), findsOneWidget);
    });

    testWidgets('a month with no items copies without asking', (tester) async {
      await pumpFixedItems(tester, fixedItemsRepository: await withoutItems());
      expect(find.text('No fixed items yet'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, copyLabel));
      await tester.pumpAndSettle();

      expect(find.text('Copy from last month?'), findsNothing);
      expect(find.text('No fixed items yet'), findsNothing);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Scholarship'), findsOneWidget);
    });

    testWidgets('the oldest month says there is nothing to copy from', (
      tester,
    ) async {
      await openAugust(tester);
      await tester.tap(copyButton());
      await tester.pumpAndSettle();

      await tester.tap(confirmButton());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'There is no earlier month with a saved salary to copy from.',
        ),
        findsOneWidget,
      );
      // Asking again changes nothing, so there is nothing to retry.
      expect(find.text('Retry'), findsNothing);
      expect(find.text('Rent'), findsOneWidget);
    });

    testWidgets('a copy that failed offers Retry, which copies', (
      tester,
    ) async {
      final demo = await pumpFixedItems(tester);
      demo.update(const DemoSettings(save: DemoSave.fails));
      await tester.tap(copyButton());
      await tester.pumpAndSettle();
      await tester.tap(confirmButton());
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't copy the items. Check your connection."),
        findsOneWidget,
      );
      expect(find.text('Rent'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Rent'), findsNWidgets(2));
    });

    testWidgets('is there in each part of a month paid in two payments', (
      tester,
    ) async {
      await pumpFixedItems(tester, settings: twoPayments);
      expect(copyButton(), findsOneWidget);

      await choosePart(tester, 'Part 2');

      expect(copyButton(), findsOneWidget);
    });

    testWidgets('is not offered for a month that is not saved', (tester) async {
      await pumpFixedItems(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      expect(find.text(copyLabel), findsNothing);
    });

    testWidgets('is in Arabic', (tester) async {
      await pumpFixedItems(tester, language: AppLanguage.arabic);

      await tester.tap(
        find.widgetWithText(TextButton, 'النسخ من الشهر الماضي'),
      );
      await tester.pumpAndSettle();

      expect(find.text('النسخ من الشهر الماضي؟'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'نسخ'), findsOneWidget);
      expect(find.textContaining(RegExp('[٠-٩]')), findsNothing);
    });
  });

  group('the balances the server calculated', () {
    // Not what the items add up to, so the server's can be told apart.
    const month = Money(1234567, Currency.rub);

    FakeServerSalaryRepository serverSalary([
      DemoSettings settings = const DemoSettings(),
    ]) {
      final demo = DemoController(initial: settings, latency: Duration.zero);
      return FakeServerSalaryRepository(FakeSalaryRepository(demo: demo))
        ..balancesOf = (_, _) => const SalaryBalances(
          first: Money(111100, Currency.rub),
          second: Money(222200, Currency.rub),
          month: month,
        );
    }

    testWidgets('are the balance shown under the items', (tester) async {
      await pumpFixedItems(tester, salaryRepository: serverSalary());

      expect(figure('12,345.67 ₽'), findsOneWidget);
      expect(figure('74,900.00 ₽'), findsNothing);
    });

    testWidgets("stay the server's after an item is added", (tester) async {
      await pumpFixedItems(tester, salaryRepository: serverSalary());

      await openAddSheet(tester);
      await fillSheet(tester, name: 'Gym', amount: '1200');
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.text('Gym'), findsOneWidget);
      expect(figure('12,345.67 ₽'), findsOneWidget);
    });

    testWidgets('are those of each part for a month paid twice', (
      tester,
    ) async {
      await pumpFixedItems(
        tester,
        settings: twoPayments,
        salaryRepository: serverSalary(twoPayments),
      );

      expect(figure('1,111.00 ₽'), findsOneWidget);

      await choosePart(tester, 'Part 2');

      expect(figure('2,222.00 ₽'), findsOneWidget);
    });
  });

  group('a failed save', () {
    testWidgets('keeps the list and offers Retry', (tester) async {
      final demo = await pumpFixedItems(tester);
      demo.update(const DemoSettings(save: DemoSave.fails));
      await openAddSheet(tester);
      await fillSheet(tester, name: 'Gym', amount: '1200');

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.text('Couldn’t save. Check your connection.'), findsNothing);
      expect(find.textContaining('save'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Gym'), findsNothing);

      demo.update(const DemoSettings());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Gym'), findsOneWidget);
    });

    testWidgets('a failed delete says it could not delete', (tester) async {
      final demo = await pumpFixedItems(tester);
      demo.update(const DemoSettings(save: DemoSave.fails));
      await openEditSheet(tester, 'Rent');
      await tester.tap(inSheet(find.text('Delete')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't delete. Check your connection."),
        findsOneWidget,
      );
      expect(find.text('Rent'), findsOneWidget);
    });
  });

  group('an item changed on another device', () {
    testWidgets('is not changed: the list is current and Apply again retries', (
      tester,
    ) async {
      final demo = DemoController(latency: Duration.zero);
      final repository = FakeFixedItemsRepository(
        demo: demo,
        salary: FakeSalaryRepository(demo: demo),
      );
      await pumpFixedItems(tester, fixedItemsRepository: repository);
      // Another device renames the rent first.
      final rent = (await repository.items(october))[1];
      await repository.update(
        october,
        rent.id,
        FixedItemDraft(
          name: 'Flat',
          amount: rent.amount,
          kind: rent.kind,
          part: rent.part,
        ),
        version: rent.version,
      );
      await openEditSheet(tester, 'Rent');
      await fillSheet(tester, name: 'Rent 2', amount: '31000');

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'This item was changed on another device. The list is up to date.',
        ),
        findsOneWidget,
      );
      expect(find.text('Flat'), findsOneWidget);
      expect(find.text('Rent 2'), findsNothing);

      await tester.tap(find.text('Apply again'));
      await tester.pumpAndSettle();

      expect(find.text('Rent 2'), findsOneWidget);
      expect(find.text('Flat'), findsNothing);
    });
  });

  group('loading, error and no connection', () {
    testWidgets('shows grey blocks while the items load', (tester) async {
      final demo = await pumpFixedItems(tester, size: const Size(412, 915));

      demo.update(demo.settings.copyWith(scenario: DemoScenario.loading));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SkeletonBox), findsWidgets);
      // The segments stay.
      expect(find.text('Month'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonBox), findsNothing);
    });

    testWidgets('an error offers Try again, which loads the items', (
      tester,
    ) async {
      final demo = await pumpFixedItems(tester);

      demo.update(demo.settings.copyWith(scenario: DemoScenario.error));
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();

      expect(find.text('Rent'), findsOneWidget);
    });

    testWidgets('no connection offers Try again', (tester) async {
      final demo = await pumpFixedItems(tester);

      demo.update(demo.settings.copyWith(scenario: DemoScenario.noConnection));
      await tester.pumpAndSettle();
      expect(find.text('No connection'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      expect(find.text('Rent'), findsOneWidget);
    });
  });

  group('the month', () {
    testWidgets('is the month of the Salary tab it was opened from', (
      tester,
    ) async {
      await pumpApp(tester);

      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/salary?month=2026-09');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fixed items'));
      await tester.pumpAndSettle();

      // September's salary is 100,050.00 ₽.
      expect(
        sumLine(
          'Salary 100,050.00 ₽ + Scholarship 5,000.00 ₽ '
          '− Rent 30,000.00 ₽ − Services 4,500.00 ₽',
        ),
        findsOneWidget,
      );
      expect(figure('70,550.00 ₽'), findsOneWidget);

      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);
    });

    testWidgets('a month with no saved salary asks to save it first', (
      tester,
    ) async {
      await pumpApp(tester, settings: twoPayments);

      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/salary/fixed-items?month=2026-03');
      await tester.pumpAndSettle();

      expect(find.text("Save this month's salary first"), findsOneWidget);
      expect(
        find.text(
          'Fixed items belong to a saved month. Save its salary, then add '
          'them here.',
        ),
        findsOneWidget,
      );
      // There is nothing to add to, count or split into parts.
      expect(find.text('No fixed items yet'), findsNothing);
      expect(find.text('Add item'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Balance after fixed items'), findsNothing);
      expect(find.text('Part 1'), findsNothing);
      // The segments and the navigation bar stay.
      expect(find.text('Month'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Go to salary opens the salary of that month', (tester) async {
      await pumpApp(tester);

      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/salary/fixed-items?month=2026-03');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Go to salary'));
      await tester.pumpAndSettle();

      expect(find.text('March 2026'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save month'), findsOneWidget);
    });

    testWidgets('an empty account has no month to add items to', (
      tester,
    ) async {
      await pumpFixedItems(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      expect(find.text("Save this month's salary first"), findsOneWidget);
      expect(find.text('Add item'), findsNothing);
    });

    testWidgets('an address with a month that does not exist shows today', (
      tester,
    ) async {
      await pumpApp(tester);

      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/salary/fixed-items?month=nonsense');
      await tester.pumpAndSettle();

      expect(figure('74,900.00 ₽'), findsOneWidget);
    });
  });

  group('in Arabic', () {
    testWidgets('shows Arabic labels and Western digits', (tester) async {
      await pumpFixedItems(tester, language: AppLanguage.arabic);

      expect(find.text('الرصيد بعد البنود الثابتة'), findsOneWidget);
      expect(find.byTooltip('تعديل Rent'), findsOneWidget);
      expect(find.text('إضافة بند'), findsOneWidget);
      expect(find.textContaining(RegExp('[٠-٩]')), findsNothing);
    });

    testWidgets('the sheet is in Arabic', (tester) async {
      await pumpFixedItems(tester, language: AppLanguage.arabic);

      await tester.tap(find.text('إضافة بند'));
      await tester.pumpAndSettle();

      expect(find.text('إضافة بند ثابت'), findsOneWidget);
      expect(inSheet(find.text('الاسم')), findsOneWidget);
      expect(inSheet(find.text('دخل')), findsOneWidget);
      expect(inSheet(find.text('مصروف')), findsOneWidget);
      expect(inSheet(find.text('حفظ')), findsOneWidget);
    });

    testWidgets('the empty state is in Arabic', (tester) async {
      await pumpFixedItems(
        tester,
        language: AppLanguage.arabic,
        fixedItemsRepository: await withoutItems(),
      );

      expect(find.text('لا توجد بنود ثابتة بعد'), findsOneWidget);
    });

    testWidgets('a month that is not saved asks to save it, in Arabic', (
      tester,
    ) async {
      await pumpFixedItems(
        tester,
        language: AppLanguage.arabic,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      expect(find.text('احفظ راتب هذا الشهر أولًا'), findsOneWidget);
      expect(find.text('الذهاب إلى الراتب'), findsOneWidget);
    });
  });

  group('large text', () {
    testWidgets('fits, with the sheet too', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpFixedItems(
        tester,
        settings: twoPayments,
        size: const Size(412, 915),
      );
      expect(tester.takeException(), isNull);

      await openEditSheet(tester, 'Rent');

      expect(tester.takeException(), isNull);
      expect(find.text('Edit fixed item'), findsOneWidget);
    });
  });
}
