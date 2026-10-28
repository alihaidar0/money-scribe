import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/app/shell/floating_navigation_bar.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/transactions/presentation/transaction_form_screen.dart';
import 'package:money_scribe/features/transactions/presentation/transactions_screen.dart';

import '../../../support/open_screen.dart';

const twoPayments = DemoSettings(paymentMode: PaymentMode.twoPayments);

Finder partSegment(String label) {
  return find.descendant(
    of: find.byType(PillSegmentedButton<PeriodScope>),
    matching: find.text(label),
  );
}

Finder inSheet(Finder finder) {
  return find.descendant(of: find.byType(BottomSheet), matching: finder);
}

/// The button that opens the Filters sheet, whichever style it has.
Finder filtersButton(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
  );
}

/// The cross of the chip of an active filter.
Finder removeChip(String label) {
  return find.descendant(
    of: find.widgetWithText(InputChip, label),
    matching: find.byIcon(LucideIcons.x),
  );
}

Future<void> openFilters(WidgetTester tester) async {
  await tester.tap(find.byIcon(LucideIcons.slidersHorizontal).first);
  await tester.pumpAndSettle();
}

void main() {
  group('one payment (TX-1)', () {
    testWidgets('is the third tab, with the title and the settings gear', (
      tester,
    ) async {
      await openTransactions(tester);

      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(find.text('Transactions'), findsWidgets);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.byType(FloatingNavigationBar), findsOneWidget);
    });

    testWidgets('lists the days newest first, each with its total', (
      tester,
    ) async {
      await openTransactions(tester);

      for (final day in [
        'Mon 19 Oct',
        'Sat 17 Oct',
        'Mon 5 Oct',
        'Thu 1 Oct',
      ]) {
        expect(find.text(day), findsOneWidget, reason: day);
      }
      final newest = tester.getTopLeft(find.text('Mon 19 Oct')).dy;
      final oldest = tester.getTopLeft(find.text('Thu 1 Oct')).dy;
      expect(newest, lessThan(oldest));
      // The total of the day is at the end of its header, and the amount is in
      // its row: each appears twice.
      expect(amountText('−640.00 ₽'), findsNWidgets(2));
      expect(amountText('−220.00 ₽'), findsNWidgets(2));
      expect(amountText('−1,284.50 ₽'), findsNWidgets(2));
      expect(amountText('+5,000.00 ₽'), findsNWidgets(2));
    });

    testWidgets('a row has the category, the note and the account', (
      tester,
    ) async {
      await openTransactions(tester);

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Weekly shopping · Card'), findsOneWidget);
      expect(find.text('Coffee · Cash'), findsOneWidget);
      // A transaction with no note shows its account alone.
      expect(find.text('Card'), findsOneWidget);
    });

    testWidgets('has the search, the Filters button and the Add button', (
      tester,
    ) async {
      await openTransactions(tester);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(filtersButton('Filters'), findsOneWidget);
      // Nothing is on, so there is no chip to take off.
      expect(find.byType(InputChip), findsNothing);
      expect(find.widgetWithText(FloatingActionButton, 'Add'), findsOneWidget);
      expect(find.byType(PillSegmentedButton<PeriodScope>), findsNothing);
    });

    testWidgets('has no part headers', (tester) async {
      await openTransactions(tester);

      expect(find.textContaining('Part 1'), findsNothing);
    });
  });

  group('two payments (TX-2)', () {
    testWidgets('has the choice Month, Part 1 and Part 2', (tester) async {
      await openTransactions(tester, settings: twoPayments);

      expect(find.byType(PillSegmentedButton<PeriodScope>), findsOneWidget);
      for (final label in ['Month', 'Part 1', 'Part 2']) {
        expect(partSegment(label), findsOneWidget);
      }
    });

    testWidgets('splits the list into parts with headers', (tester) async {
      await openTransactions(tester, settings: twoPayments);

      // The pay days are the 20th and the 5th: the 5th to the 19th is a part
      // of its own, and the 1st is the end of the part before it.
      expect(find.text('Part 2 · 5 Oct – 19 Oct'), findsOneWidget);
      expect(find.text('Part 1 · 20 Sep – 4 Oct'), findsOneWidget);
      final part2 = tester.getTopLeft(find.text('Part 2 · 5 Oct – 19 Oct')).dy;
      final part1 = tester.getTopLeft(find.text('Part 1 · 20 Sep – 4 Oct')).dy;
      final taxi = tester.getTopLeft(find.text('Mon 19 Oct')).dy;
      final groceries = tester.getTopLeft(find.text('Mon 5 Oct')).dy;
      final scholarship = tester.getTopLeft(find.text('Thu 1 Oct')).dy;
      expect(part2, lessThan(taxi));
      expect(groceries, lessThan(part1));
      expect(part1, lessThan(scholarship));
    });

    testWidgets('Part 1 shows only the days from the first pay day', (
      tester,
    ) async {
      await openTransactions(tester, settings: twoPayments);

      await tester.tap(partSegment('Part 1'));
      await tester.pumpAndSettle();

      expect(find.text('Thu 1 Oct'), findsOneWidget);
      expect(find.text('Mon 5 Oct'), findsNothing);
      expect(find.text('Mon 19 Oct'), findsNothing);
      expect(find.text('Part 2 · 5 Oct – 19 Oct'), findsNothing);
    });

    testWidgets('Part 2 shows only the days from the second pay day', (
      tester,
    ) async {
      await openTransactions(tester, settings: twoPayments);

      await tester.tap(partSegment('Part 2'));
      await tester.pumpAndSettle();

      expect(find.text('Mon 19 Oct'), findsOneWidget);
      expect(find.text('Sat 17 Oct'), findsOneWidget);
      expect(find.text('Mon 5 Oct'), findsOneWidget);
      expect(find.text('Thu 1 Oct'), findsNothing);
    });

    testWidgets('Month shows everything again', (tester) async {
      await openTransactions(tester, settings: twoPayments);
      await tester.tap(partSegment('Part 2'));
      await tester.pumpAndSettle();

      await tester.tap(partSegment('Month'));
      await tester.pumpAndSettle();

      expect(find.text('Mon 5 Oct'), findsOneWidget);
      expect(find.text('Mon 19 Oct'), findsOneWidget);
    });
  });

  group('the search', () {
    /// Types [text] and waits for the search to ask: it waits half a second
    /// after the last key.
    Future<void> search(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
    }

    testWidgets('filters the list while typing', (tester) async {
      await openTransactions(tester);

      await search(tester, 'coffee');

      expect(find.text('Dining'), findsOneWidget);
      expect(find.text('Transport'), findsNothing);
      expect(find.text('Groceries'), findsNothing);
    });

    testWidgets('no match says so and offers Clear filters (TX-8)', (
      tester,
    ) async {
      await openTransactions(tester);

      await search(tester, 'xyz');

      expect(find.text('No results'), findsOneWidget);
      expect(find.text('Try another word or clear the filters.'), findsOne);
      expect(find.widgetWithText(FilledButton, 'Clear filters'), findsOne);
      // The search and the Filters button stay.
      expect(find.byType(TextField), findsOneWidget);
      // The first is the button; the demo panel handle has the same icon.
      expect(find.byIcon(LucideIcons.slidersHorizontal), findsWidgets);
    });

    testWidgets('Clear filters brings the list back and empties the search', (
      tester,
    ) async {
      await openTransactions(tester);
      await search(tester, 'xyz');

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('Transport'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty,
      );
    });
  });

  group('the filters (TX-3)', () {
    testWidgets('a chip opens the sheet with the categories and accounts', (
      tester,
    ) async {
      await openTransactions(tester);

      await openFilters(tester);

      expect(inSheet(find.text('Filters')), findsOneWidget);
      for (final name in [
        'Groceries',
        'Dining',
        'Transport',
        'Housing',
        'Utilities',
        'Other',
      ]) {
        expect(inSheet(find.text(name)), findsOneWidget, reason: name);
      }
      expect(inSheet(find.text('Card')), findsOneWidget);
      expect(inSheet(find.text('Cash')), findsOneWidget);
      expect(inSheet(find.text('From')), findsOneWidget);
      expect(inSheet(find.text('To')), findsOneWidget);
      expect(inSheet(find.text('Reset')), findsOneWidget);
      expect(inSheet(find.text('Apply')), findsOneWidget);
      // One payment has no choice of period.
      expect(inSheet(find.text('Period')), findsNothing);
    });

    testWidgets('the Filters button opens the sheet', (tester) async {
      await openTransactions(tester);

      await tester.tap(filtersButton('Filters'));
      await tester.pumpAndSettle();

      expect(inSheet(find.text('Filters')), findsOneWidget);
    });

    testWidgets('Apply narrows the list to the chosen category', (
      tester,
    ) async {
      await openTransactions(tester);
      await openFilters(tester);

      await tester.tap(inSheet(find.text('Transport')));
      await tester.tap(inSheet(find.text('Apply')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Taxi · Card'), findsOneWidget);
      expect(find.text('Coffee · Cash'), findsNothing);
      // The button says how many choices are on, and a chip names this one.
      expect(filtersButton('Filters · 1'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Transport'), findsOneWidget);
    });

    testWidgets('the cross of a chip takes that choice off', (tester) async {
      await openTransactions(tester);
      await openFilters(tester);
      await tester.tap(inSheet(find.text('Transport')));
      await tester.tap(inSheet(find.text('Cash')));
      await tester.tap(inSheet(find.text('Apply')));
      await tester.pumpAndSettle();
      expect(filtersButton('Filters · 2'), findsOneWidget);

      await tester.tap(removeChip('Transport'));
      await tester.pumpAndSettle();

      expect(filtersButton('Filters · 1'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Transport'), findsNothing);
      expect(find.widgetWithText(InputChip, 'Cash'), findsOneWidget);
      expect(find.text('Coffee · Cash'), findsOneWidget);
      expect(find.text('Taxi · Card'), findsNothing);

      await tester.tap(removeChip('Cash'));
      await tester.pumpAndSettle();

      expect(filtersButton('Filters'), findsOneWidget);
      expect(find.text('Taxi · Card'), findsOneWidget);
    });

    testWidgets('Apply narrows by account', (tester) async {
      await openTransactions(tester);
      await openFilters(tester);

      await tester.tap(inSheet(find.text('Cash')));
      await tester.tap(inSheet(find.text('Apply')));
      await tester.pumpAndSettle();

      expect(find.text('Coffee · Cash'), findsOneWidget);
      expect(find.text('Taxi · Card'), findsNothing);
      expect(find.widgetWithText(InputChip, 'Cash'), findsOneWidget);
    });

    testWidgets('Apply narrows by a day range', (tester) async {
      await openTransactions(tester);
      await openFilters(tester);

      await tester.tap(inSheet(find.text('From')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('17'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Apply')));
      await tester.pumpAndSettle();

      expect(find.text('Sat 17 Oct'), findsOneWidget);
      expect(find.text('Mon 19 Oct'), findsOneWidget);
      expect(find.text('Mon 5 Oct'), findsNothing);
      expect(find.widgetWithText(InputChip, 'From 17 Oct'), findsOneWidget);

      await tester.tap(removeChip('From 17 Oct'));
      await tester.pumpAndSettle();

      expect(find.text('Mon 5 Oct'), findsOneWidget);
    });

    testWidgets('the choices are kept when the sheet opens again', (
      tester,
    ) async {
      await openTransactions(tester);
      await openFilters(tester);
      await tester.tap(inSheet(find.text('Transport')));
      await tester.tap(inSheet(find.text('Apply')));
      await tester.pumpAndSettle();

      await tester.tap(filtersButton('Filters · 1'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilterChip>(
              find.descendant(
                of: find.byType(BottomSheet),
                matching: find.widgetWithText(FilterChip, 'Transport'),
              ),
            )
            .selected,
        isTrue,
      );
    });

    testWidgets('Reset clears the choices and closes', (tester) async {
      await openTransactions(tester);
      await openFilters(tester);
      await tester.tap(inSheet(find.text('Transport')));
      await tester.tap(inSheet(find.text('Apply')));
      await tester.pumpAndSettle();

      await tester.tap(filtersButton('Filters · 1'));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Reset')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Coffee · Cash'), findsOneWidget);
      expect(filtersButton('Filters'), findsOneWidget);
    });

    testWidgets('dismissing the sheet changes nothing', (tester) async {
      await openTransactions(tester);
      await openFilters(tester);
      await tester.tap(inSheet(find.text('Transport')));

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Coffee · Cash'), findsOneWidget);
    });

    testWidgets('a filter with no match shows No results', (tester) async {
      await openTransactions(tester);
      await openFilters(tester);

      await tester.tap(inSheet(find.text('Housing')));
      await tester.tap(inSheet(find.text('Apply')));
      await tester.pumpAndSettle();

      expect(find.text('No results'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets('two payments add the choice of period (TX-3b)', (
      tester,
    ) async {
      await openTransactions(tester, settings: twoPayments);

      await openFilters(tester);

      expect(inSheet(find.text('Period')), findsOneWidget);
      for (final label in ['Month', 'Part 1', 'Part 2']) {
        expect(inSheet(find.text(label)), findsOneWidget, reason: label);
      }
    });

    testWidgets('the period applies as a part of the month', (tester) async {
      await openTransactions(tester, settings: twoPayments);
      await openFilters(tester);

      await tester.tap(inSheet(find.text('Part 2')));
      await tester.tap(inSheet(find.text('Apply')));
      await tester.pumpAndSettle();

      expect(find.text('Mon 19 Oct'), findsOneWidget);
      expect(find.text('Thu 1 Oct'), findsNothing);
      // The choice above the list follows.
      expect(
        tester
            .widget<PillSegmentedButton<PeriodScope>>(
              find.byType(PillSegmentedButton<PeriodScope>),
            )
            .selected,
        {PeriodScope.secondPart},
      );
    });
  });

  group('opening a transaction', () {
    testWidgets('a row opens it to be changed (TX-5)', (tester) async {
      await openTransactions(tester);

      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionFormScreen), findsOneWidget);
      expect(find.text('Edit transaction'), findsOneWidget);
      expect(find.byType(FloatingNavigationBar), findsNothing);
    });

    testWidgets('Add opens the form for a new one (TX-4)', (tester) async {
      await openTransactions(tester);

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('Add transaction'), findsOneWidget);
    });

    testWidgets('coming back shows what changed', (tester) async {
      await openTransactions(tester);

      await tester.tap(find.text('Transport'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(LucideIcons.trash2));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(find.text('Transport'), findsNothing);
      expect(find.text('Mon 19 Oct'), findsNothing);
    });
  });

  group('a wide window (TB-1)', () {
    const wide = Size(1280, 800);

    testWidgets('shows the newest transaction beside the list', (tester) async {
      await openTransactions(tester, size: wide);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Edit'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Delete'), findsOneWidget);
      // The amount is in the day's total, the row and the pane.
      expect(amountText('−640.00 ₽'), findsNWidgets(3));
    });

    testWidgets('a phone has no detail pane', (tester) async {
      await openTransactions(tester);

      expect(find.text('Category'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Delete'), findsNothing);
    });

    testWidgets('a row shows its transaction instead of opening it', (
      tester,
    ) async {
      await openTransactions(tester, size: wide);

      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionFormScreen), findsNothing);
      // Day total, row and pane.
      expect(amountText('−1,284.50 ₽'), findsNWidgets(3));
      expect(amountText('−640.00 ₽'), findsNWidgets(2));
      // The pane shows the note alone; the row joins it with the account.
      expect(find.text('Weekly shopping'), findsOneWidget);
    });

    testWidgets('the detail has the date, the account and the note', (
      tester,
    ) async {
      await openTransactions(tester, size: wide);

      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Mon 5 Oct'), findsNWidgets(2));
    });

    testWidgets('Edit opens the form of the shown transaction', (tester) async {
      await openTransactions(tester, size: wide);

      await tester.tap(find.widgetWithText(FilledButton, 'Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit transaction'), findsOneWidget);
    });

    testWidgets('Delete asks first, and Cancel keeps it', (tester) async {
      await openTransactions(tester, size: wide);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete transaction?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // The row and the pane.
      expect(find.text('Transport'), findsNWidgets(2));
    });

    testWidgets('confirming Delete removes it and shows the next', (
      tester,
    ) async {
      await openTransactions(tester, size: wide);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Transport'), findsNothing);
      expect(find.text('Mon 19 Oct'), findsNothing);
      // The next newest is shown: the day's total, the row and the pane.
      expect(amountText('−220.00 ₽'), findsNWidgets(3));
    });

    testWidgets('a failed Delete says so and offers Retry', (tester) async {
      final demo = await openTransactions(tester, size: wide);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
      await tester.pumpAndSettle();
      demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't delete. Check your connection."), findsOne);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('no transactions (TX-10)', () {
    const empty = DemoSettings(scenario: DemoScenario.empty);

    testWidgets('says so and offers to add the first purchase', (tester) async {
      await openTransactions(tester, settings: empty);

      expect(find.text('No transactions yet'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Add your first purchase'),
        findsOneWidget,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('the button opens the form, and the first one is listed', (
      tester,
    ) async {
      await openTransactions(tester, settings: empty);

      await tester.tap(find.text('Add your first purchase'));
      await tester.pumpAndSettle();
      expect(find.text('Add transaction'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '99');
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('No transactions yet'), findsNothing);
      // A transaction of today has a header of its own.
      expect(find.text('Today'), findsOneWidget);
      expect(amountText('−99.00 ₽'), findsNWidgets(2));
    });
  });

  group('loading, error and no connection', () {
    testWidgets('shows grey blocks while the transactions load (TX-9)', (
      tester,
    ) async {
      final demo = await openTransactions(tester, size: const Size(412, 915));

      demo.update(demo.settings.copyWith(scenario: DemoScenario.loading));
      // Long enough for the button to finish leaving.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(FloatingActionButton), findsNothing);

      demo.update(const DemoSettings());
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonBox), findsNothing);
    });

    testWidgets('an error offers Try again (TX-11)', (tester) async {
      final demo = await openTransactions(tester);

      demo.update(demo.settings.copyWith(scenario: DemoScenario.error));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load transactions"), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets('no connection offers Try again (TX-12)', (tester) async {
      final demo = await openTransactions(tester);

      demo.update(demo.settings.copyWith(scenario: DemoScenario.noConnection));
      await tester.pumpAndSettle();
      expect(find.text('No connection'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      expect(find.text('Transport'), findsOneWidget);
    });
  });

  group('in Arabic', () {
    testWidgets('shows Arabic labels, Western digits and a mirrored list', (
      tester,
    ) async {
      await openTransactions(
        tester,
        language: AppLanguage.arabic,
        settings: twoPayments,
      );

      expect(find.text('بحث'), findsOneWidget);
      expect(find.text('عوامل التصفية'), findsOneWidget);
      expect(find.text('إضافة'), findsOneWidget);
      expect(find.textContaining(RegExp('[٠-٩]')), findsNothing);
      expect(find.textContaining('الجزء 2 · 5 '), findsOneWidget);
    });

    testWidgets('the filters sheet is in Arabic', (tester) async {
      await openTransactions(tester, language: AppLanguage.arabic);

      await tester.tap(find.byIcon(LucideIcons.slidersHorizontal).first);
      await tester.pumpAndSettle();

      expect(inSheet(find.text('عوامل التصفية')), findsOneWidget);
      expect(inSheet(find.text('تطبيق')), findsOneWidget);
      expect(inSheet(find.text('إعادة تعيين')), findsOneWidget);
    });

    testWidgets('an empty list says so in Arabic', (tester) async {
      await openTransactions(
        tester,
        language: AppLanguage.arabic,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      expect(find.text('لا توجد معاملات بعد'), findsOneWidget);
    });
  });
}
