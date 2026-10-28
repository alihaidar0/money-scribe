import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/app/shell/floating_navigation_bar.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/widgets/month_chip.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/features/debts/presentation/debt_details_screen.dart';
import 'package:money_scribe/features/reports/bloc/reports_bloc.dart';
import 'package:money_scribe/features/reports/presentation/reports_screen.dart';
import 'package:money_scribe/features/reports/presentation/widgets/donut_chart.dart';
import 'package:money_scribe/features/salary/presentation/fixed_items_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/transactions/presentation/transactions_screen.dart';

import '../../../support/open_screen.dart';
import '../../../support/other_currency_repositories.dart';

const _twoPayments = DemoSettings(paymentMode: PaymentMode.twoPayments);

Finder view(String label) {
  return find.descendant(
    of: find.byType(PillSegmentedButton<ReportsView>),
    matching: find.text(label),
  );
}

Future<void> tapView(WidgetTester tester, String label) async {
  await tester.tap(view(label));
  await tester.pumpAndSettle();
}

void main() {
  group('the page (RP-1)', () {
    testWidgets('is the fifth tab, with the title, the gear and the segments', (
      tester,
    ) async {
      await openReports(tester);

      expect(find.byType(ReportsScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Reports'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.byType(FloatingNavigationBar), findsOneWidget);
      for (final label in ['Categories', 'Month vs month', 'Debts']) {
        expect(view(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('shows October, the month of today', (tester) async {
      await openReports(tester);

      expect(find.byType(MonthChip), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('has no part selector for one payment', (tester) async {
      await openReports(tester);

      expect(find.text('Part 1'), findsNothing);
    });
  });

  group('the categories (RP-1)', () {
    testWidgets('shows the total in the ring and a row for each category', (
      tester,
    ) async {
      await openReports(tester);

      expect(find.byType(DonutChart), findsOneWidget);
      // The total is in the centre of the ring, and not in a row.
      expect(amountText('52,750.00 ₽'), findsOneWidget);
      for (final entry in {
        'Housing': ('30,000.00 ₽', '56.9%'),
        'Groceries': ('9,800.00 ₽', '18.6%'),
        'Utilities': ('4,500.00 ₽', '8.5%'),
        'Transport': ('3,400.00 ₽', '6.4%'),
        'Dining': ('3,150.00 ₽', '6.0%'),
        'Other': ('1,900.00 ₽', '3.6%'),
      }.entries) {
        expect(find.text(entry.key), findsOneWidget, reason: entry.key);
        expect(amountText(entry.value.$1), findsOneWidget, reason: entry.key);
        expect(find.text(entry.value.$2), findsOneWidget, reason: entry.key);
      }
    });

    testWidgets('says how the spending changed since September', (
      tester,
    ) async {
      await openReports(tester);

      expect(find.text(amount('vs September −3,200.00 ₽')), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowDown), findsOneWidget);
    });

    testWidgets('a row opens the transactions of that category', (
      tester,
    ) async {
      await openReports(tester);

      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Transactions'), findsOneWidget);
      // The chips show the category and the days are the month.
      expect(find.text('Filters · 2'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Groceries'), findsOneWidget);
      expect(find.widgetWithText(InputChip, '1 Oct – 31 Oct'), findsOneWidget);
      expect(find.text('Weekly shopping'), findsNothing);
      expect(find.textContaining('Weekly shopping'), findsOneWidget);
      expect(find.text('Dining'), findsNothing);
    });

    testWidgets('picking another month shows its figures', (tester) async {
      await openReports(tester);

      await tester.tap(find.byType(MonthChip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sep'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
      expect(amountText('55,950.00 ₽'), findsOneWidget);
      expect(find.text(amount('vs August −3,200.00 ₽')), findsNothing);
    });
  });

  group('two payments (RP-2)', () {
    testWidgets('has the part selector, on the whole month first', (
      tester,
    ) async {
      await openReports(tester, settings: _twoPayments);

      for (final label in ['Month', 'Part 1', 'Part 2']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(amountText('52,750.00 ₽'), findsOneWidget);
    });

    testWidgets('Part 1 shows its own spending and compares the same part', (
      tester,
    ) async {
      await openReports(tester, settings: _twoPayments);

      await tester.tap(find.text('Part 1'));
      await tester.pumpAndSettle();

      expect(amountText('42,750.00 ₽'), findsOneWidget);
      expect(find.text('56.9%'), findsNothing);
      expect(find.text('70.2%'), findsOneWidget);
      expect(
        find.text(amount('vs September Part 1 −2,550.00 ₽')),
        findsOneWidget,
      );
    });

    testWidgets('Part 2 leaves out a category with nothing spent', (
      tester,
    ) async {
      await openReports(tester, settings: _twoPayments);

      await tester.tap(find.text('Part 2'));
      await tester.pumpAndSettle();

      expect(amountText('10,000.00 ₽'), findsOneWidget);
      expect(find.text('Housing'), findsNothing);
    });
  });

  group('month vs month (RP-3, RP-4)', () {
    testWidgets('shows the income and the spending of both months', (
      tester,
    ) async {
      await openReports(tester);

      await tapView(tester, 'Month vs month');

      // Under the bars, and as the title of its table.
      expect(find.text('Income'), findsNWidgets(2));
      expect(find.text('Spent'), findsNWidgets(2));
      expect(amountText('105,050.00 ₽'), findsOneWidget);
      expect(amountText('109,400.00 ₽'), findsOneWidget);
      expect(amountText('55,950.00 ₽'), findsOneWidget);
      expect(amountText('52,750.00 ₽'), findsOneWidget);
      expect(amountText('+4,350.00 ₽'), findsOneWidget);
      expect(amountText('−3,200.00 ₽'), findsOneWidget);
      expect(find.text('September 2026'), findsWidgets);
      expect(find.text('October 2026'), findsWidgets);
    });

    testWidgets('compares the same part for two payments', (tester) async {
      await openReports(tester, settings: _twoPayments);
      await tapView(tester, 'Month vs month');
      await tester.tap(find.text('Part 1'));
      await tester.pumpAndSettle();

      expect(find.text('Part 1 · September 2026'), findsWidgets);
      expect(find.text('Part 1 · October 2026'), findsWidgets);
      expect(amountText('45,300.00 ₽'), findsOneWidget);
      expect(amountText('42,750.00 ₽'), findsOneWidget);
      expect(amountText('+0.00 ₽'), findsOneWidget);
      expect(amountText('−2,550.00 ₽'), findsOneWidget);
    });

    testWidgets('keeps the month when the segment changes', (tester) async {
      await openReports(tester);
      await tester.tap(find.byType(MonthChip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sep'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      await tapView(tester, 'Month vs month');

      expect(find.text('September 2026'), findsWidgets);
      expect(find.text('August 2026'), findsWidgets);
    });
  });

  group('choosing the month to compare with', () {
    testWidgets('only the month comparison has the chip', (tester) async {
      await openReports(tester);

      expect(find.text('Compare with'), findsNothing);
      expect(find.byType(MonthChip), findsOneWidget);

      await tapView(tester, 'Month vs month');

      expect(find.text('Compare with'), findsOneWidget);
      expect(find.byType(MonthChip), findsNWidgets(2));
    });

    testWidgets('starts with the month before', (tester) async {
      await openReports(tester);
      await tapView(tester, 'Month vs month');

      final compare = tester.widget<MonthChip>(find.byType(MonthChip).last);

      expect(compare.month.month, 9);
    });

    testWidgets('another month changes the table', (tester) async {
      await openReports(tester);
      await tapView(tester, 'Month vs month');

      await tester.tap(find.byType(MonthChip).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jul'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('July 2026'), findsWidgets);
      expect(find.text('September 2026'), findsNothing);
      expect(amountText('53,600.00 ₽'), findsOneWidget);
      expect(amountText('−850.00 ₽'), findsOneWidget);
    });

    testWidgets('the Categories line names the month compared with', (
      tester,
    ) async {
      await openReports(tester);
      await tapView(tester, 'Month vs month');
      await tester.tap(find.byType(MonthChip).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jul'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      await tapView(tester, 'Categories');

      expect(find.text(amount('vs July −850.00 ₽')), findsOneWidget);
    });
  });

  group('each part of a month (two payments)', () {
    testWidgets('the Categories view shows a card for each part', (
      tester,
    ) async {
      await openReports(tester, settings: _twoPayments);

      expect(find.text('By part'), findsOneWidget);
      expect(find.text('Part 1 · 20 Oct – 4 Nov'), findsOneWidget);
      expect(find.text('Part 2 · 5 Nov – 19 Nov'), findsOneWidget);
      expect(amountText('43,500.00 ₽'), findsOneWidget);
      expect(amountText('42,750.00 ₽'), findsOneWidget);
      expect(amountText('10,000.00 ₽'), findsOneWidget);
    });

    testWidgets('shows the days of the chosen period', (tester) async {
      await openReports(tester, settings: _twoPayments);

      expect(find.text('20 Oct – 19 Nov'), findsOneWidget);

      await tester.tap(find.text('Part 2 · 5 Nov – 19 Nov'));
      await tester.pumpAndSettle();

      expect(find.text('5 Nov – 19 Nov'), findsOneWidget);
    });

    testWidgets('a card shows that part', (tester) async {
      await openReports(tester, settings: _twoPayments);

      await tester.tap(find.text('Part 2 · 5 Nov – 19 Nov'));
      await tester.pumpAndSettle();

      expect(find.text('By part'), findsNothing);
      expect(amountText('10,000.00 ₽'), findsWidgets);
      expect(find.text('Housing'), findsNothing);
    });

    testWidgets('the month comparison has the cards too', (tester) async {
      await openReports(tester, settings: _twoPayments);

      await tapView(tester, 'Month vs month');

      expect(find.text('By part'), findsOneWidget);
      expect(find.text('Part 1 · 20 Oct – 4 Nov'), findsOneWidget);
    });

    testWidgets('a single part has no cards, nor has one payment', (
      tester,
    ) async {
      await openReports(tester, settings: _twoPayments);
      await tester.tap(find.text('Part 1').first);
      await tester.pumpAndSettle();
      expect(find.text('By part'), findsNothing);

      await openReports(tester);
      expect(find.text('By part'), findsNothing);
    });
  });

  group('debts (RP-5)', () {
    testWidgets('shows what is owed, then the overdue and the open debts', (
      tester,
    ) async {
      await openReports(tester);

      await tapView(tester, 'Debts');

      expect(find.text('Owed to you'), findsOneWidget);
      expect(find.text('You owe'), findsOneWidget);
      expect(amountText('8,500.00 ₽'), findsOneWidget);
      expect(amountText('0.00 ₽'), findsOneWidget);
      expect(find.text('Overdue (1)'), findsOneWidget);
      expect(find.text('Open (1)'), findsOneWidget);
      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.byType(MonthChip), findsNothing);
    });

    testWidgets('a row opens the debt', (tester) async {
      await openReports(tester);
      await tapView(tester, 'Debts');

      await tester.tap(find.text('Maria'));
      await tester.pumpAndSettle();

      expect(find.byType(DebtDetailsScreen), findsOneWidget);
      expect(find.byType(FloatingNavigationBar), findsNothing);
    });
  });

  group('states (RP-6 to RP-9)', () {
    testWidgets('shows a skeleton while loading', (tester) async {
      final demo = await openReports(tester);

      demo.update(const DemoSettings(scenario: DemoScenario.loading));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(DonutChart), findsNothing);

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
    });

    testWidgets('invites the first purchase when there is no data', (
      tester,
    ) async {
      await openReports(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      expect(find.text('Not enough data yet'), findsOneWidget);
      expect(
        find.text('Add a few transactions to see your reports.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Add a purchase'));
      await tester.pumpAndSettle();

      expect(find.text('Add transaction'), findsWidgets);
      expect(find.byType(FloatingNavigationBar), findsNothing);
    });

    testWidgets('offers Try again after an error', (tester) async {
      final demo = await openReports(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.error),
      );

      expect(find.text("Couldn't load your reports"), findsOneWidget);

      // Still failing: it asks again and shows the failure again.
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load your reports"), findsOneWidget);

      // Once the server answers, the page shows the figures.
      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      expect(find.byType(DonutChart), findsOneWidget);
    });

    testWidgets('offers Try again when there is no connection', (tester) async {
      final demo = await openReports(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.noConnection),
      );

      expect(find.text('No connection'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('No connection'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      expect(find.byType(DonutChart), findsOneWidget);
    });
  });

  testWidgets('is laid out right to left in Arabic', (tester) async {
    await openReports(tester, language: AppLanguage.arabic);

    expect(find.text('التقارير'), findsWidgets);
    expect(find.text('الفئات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('the fixed costs and other currencies', () {
    testWidgets('the fixed costs are a slice of the spending', (tester) async {
      await openReports(
        tester,
        reportsRepository: (demo) => OtherCurrencyReportsRepository(demo: demo),
      );

      expect(find.text('Fixed costs'), findsOneWidget);
      expect(amountText('8,000.00 ₽'), findsOneWidget);
      // 8,000 of 12,000.
      expect(find.textContaining('66.7'), findsOneWidget);
    });

    testWidgets('the fixed costs slice opens the fixed items, not purchases', (
      tester,
    ) async {
      await openReports(
        tester,
        reportsRepository: (demo) => OtherCurrencyReportsRepository(demo: demo),
      );

      await tester.tap(find.text('Fixed costs'));
      await tester.pumpAndSettle();

      expect(find.byType(FixedItemsScreen), findsOneWidget);
    });

    testWidgets('records in other currencies are noted on the spending', (
      tester,
    ) async {
      await openReports(
        tester,
        reportsRepository: (demo) => OtherCurrencyReportsRepository(demo: demo),
      );

      expect(
        find.text(
          'Records in other currencies are not included in these figures.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('and on the comparison, but not on the debts', (tester) async {
      await openReports(
        tester,
        reportsRepository: (demo) => OtherCurrencyReportsRepository(demo: demo),
      );

      await tapView(tester, 'Month vs month');
      expect(
        find.textContaining('Records in other currencies'),
        findsOneWidget,
      );

      await tapView(tester, 'Debts');
      expect(find.textContaining('Records in other currencies'), findsNothing);
      expect(
        find.text(
          'Debts in other currencies are not included in these totals.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an ordinary month has no note', (tester) async {
      await openReports(tester);

      expect(find.textContaining('other currencies'), findsNothing);
    });
  });

  group('a month with nothing in it', () {
    const empty = DemoSettings(scenario: DemoScenario.empty);

    testWidgets('keeps the controls, so another month can be chosen', (
      tester,
    ) async {
      await openReports(tester, settings: empty);

      expect(find.text('Not enough data yet'), findsOneWidget);
      expect(find.byType(MonthChip), findsOneWidget);
      expect(view('Debts'), findsOneWidget);
    });

    testWidgets('does not hide the debts', (tester) async {
      await openReports(tester, settings: empty);

      await tapView(tester, 'Debts');

      expect(find.text('Not enough data yet'), findsNothing);
      expect(find.text('No open debts.'), findsOneWidget);
    });
  });
}
