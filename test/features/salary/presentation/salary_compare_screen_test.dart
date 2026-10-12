import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/core/widgets/month_chip.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/features/salary/presentation/salary_compare_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_history_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/render_screen.dart';
import 'salary_test_helpers.dart';

/// A figure exactly as the table shows it.
Finder figure(String text) => find.text(amount(text));

Finder segment(String label) {
  return find.descendant(
    of: find.byType(SegmentedButton<PeriodScope>),
    matching: find.text(label),
  );
}

const twoPayments = DemoSettings(paymentMode: PaymentMode.twoPayments);

void main() {
  // The columns are chosen by how wide the figures are, so use the real fonts.
  setUpAll(loadAppFonts);

  group('one payment (SAL-8)', () {
    testWidgets('has the title, the back arrow and no navigation bar', (
      tester,
    ) async {
      await pumpCompare(tester);

      expect(find.byType(SalaryCompareScreen), findsOneWidget);
      expect(find.text('Compare months'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('compares the two newest months, the earlier first', (
      tester,
    ) async {
      await pumpCompare(tester);

      final chips = find.byType(MonthChip);
      expect(chips, findsNWidgets(2));
      expect(
        find.descendant(of: chips.first, matching: find.text('September 2026')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: chips.last, matching: find.text('October 2026')),
        findsOneWidget,
      );
      expect(find.byTooltip('Swap months'), findsOneWidget);
    });

    testWidgets('has the columns Line, the two months and Difference', (
      tester,
    ) async {
      await pumpCompare(tester);

      for (final heading in ['Line', 'September', 'October', 'Difference']) {
        expect(find.text(heading), findsOneWidget);
      }
    });

    testWidgets('has the three lines with both figures and the difference', (
      tester,
    ) async {
      await pumpCompare(tester);

      expect(find.text('Income before tax'), findsOneWidget);
      expect(find.text('Tax'), findsOneWidget);
      expect(find.text('Total after tax'), findsOneWidget);
      for (final text in [
        '115,000.00 ₽',
        '120,000.00 ₽',
        '+5,000.00 ₽',
        '14,950.00 ₽',
        '15,600.00 ₽',
        '+650.00 ₽',
        '100,050.00 ₽',
        '104,400.00 ₽',
        '+4,350.00 ₽',
      ]) {
        expect(figure(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('has no choice of part', (tester) async {
      await pumpCompare(tester);

      expect(find.byType(SegmentedButton<PeriodScope>), findsNothing);
    });

    testWidgets('the back arrow returns to the history', (tester) async {
      await pumpCompare(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryHistoryScreen), findsOneWidget);
    });
  });

  group('swapping and choosing months', () {
    testWidgets('the swap button puts each month on the other side', (
      tester,
    ) async {
      await pumpCompare(tester);

      await tester.tap(find.byTooltip('Swap months'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(MonthChip).first,
          matching: find.text('October 2026'),
        ),
        findsOneWidget,
      );
      // A true minus sign: the later month is now the first one.
      expect(figure('−4,350.00 ₽'), findsOneWidget);
      expect(figure('−5,000.00 ₽'), findsOneWidget);
    });

    testWidgets('on a phone the chips sit one under the other', (tester) async {
      await pumpCompare(tester);

      final first = tester.getCenter(find.byType(MonthChip).first);
      final last = tester.getCenter(find.byType(MonthChip).last);
      expect(first.dy, lessThan(last.dy));
      expect(find.byIcon(Icons.swap_vert), findsOneWidget);
      // Each name stays on one line inside its chip.
      expect(tester.getSize(find.byType(MonthChip).first).height, 48);
    });

    testWidgets('on a wide screen the chips sit side by side', (tester) async {
      await pumpCompare(tester, size: const Size(1000, 800));

      final first = tester.getCenter(find.byType(MonthChip).first);
      final last = tester.getCenter(find.byType(MonthChip).last);
      expect(first.dy, last.dy);
      expect(first.dx, lessThan(last.dx));
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
      // The width the layout counted on is the width the chip takes.
      final chip = find.byType(MonthChip).first;
      expect(
        tester.getSize(chip).width,
        closeTo(
          MonthChip.naturalWidth(
            tester.element(chip),
            const YearMonth(2026, 9),
          ),
          1,
        ),
      );
    });

    testWidgets('a chip opens the month picker and the chosen month stays', (
      tester,
    ) async {
      await pumpCompare(tester);

      await tester.tap(find.byType(MonthChip).first);
      await tester.pumpAndSettle();
      expect(find.text('Choose month'), findsOneWidget);

      await tester.tap(find.text('Aug'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('August 2026'), findsOneWidget);
      expect(find.text('September 2026'), findsNothing);
      // August and October are paid the same.
      expect(figure('+0.00 ₽'), findsNWidgets(3));
    });

    testWidgets('dismissing the picker changes nothing', (tester) async {
      await pumpCompare(tester);

      await tester.tap(find.byType(MonthChip).last);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsOneWidget);
      expect(figure('+4,350.00 ₽'), findsOneWidget);
    });

    testWidgets('a month with no saved salary shows dashes', (tester) async {
      await pumpCompare(tester);

      await tester.tap(find.byType(MonthChip).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jul'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('July 2026'), findsOneWidget);
      // Three figures and three differences.
      expect(find.text('—'), findsNWidgets(6));
      expect(figure('115,000.00 ₽'), findsOneWidget);
    });

    testWidgets('the same month in two years is named with its year', (
      tester,
    ) async {
      await pumpCompare(tester);

      await tester.tap(find.byType(MonthChip).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oct'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // October 2025 against October 2026: the headings carry the year.
      expect(find.text('October 2025'), findsNWidgets(2));
      expect(find.text('October 2026'), findsNWidgets(2));
    });
  });

  group('two payments (SAL-9)', () {
    testWidgets('has the choice Month, Part 1 and Part 2', (tester) async {
      await pumpCompare(tester, settings: twoPayments);

      expect(find.byType(SegmentedButton<PeriodScope>), findsOneWidget);
      for (final label in ['Month', 'Part 1', 'Part 2']) {
        expect(segment(label), findsOneWidget);
      }
      // The whole month is compared first.
      expect(find.text('Total after tax'), findsOneWidget);
      expect(find.text('Pay after tax'), findsNothing);
    });

    testWidgets('Part 2 compares the pay, the fixed items and the balance', (
      tester,
    ) async {
      await pumpCompare(tester, settings: twoPayments);

      await tester.tap(segment('Part 2'));
      await tester.pumpAndSettle();

      expect(find.text('Pay after tax'), findsOneWidget);
      expect(find.text('Fixed items'), findsOneWidget);
      expect(find.text('Balance after fixed items'), findsOneWidget);
      expect(find.text('Total after tax'), findsNothing);
      // Pay after tax, then the fixed items (signed), then the balance.
      for (final text in [
        '56,550.00 ₽',
        '60,900.00 ₽',
        '+5,000.00 ₽',
        '61,550.00 ₽',
        '65,900.00 ₽',
      ]) {
        expect(figure(text), findsWidgets, reason: text);
      }
      expect(figure('+5,000.00 ₽'), findsNWidgets(2));
      // The pay and the balance both differ by the same amount.
      expect(figure('+4,350.00 ₽'), findsNWidgets(2));
      expect(figure('+0.00 ₽'), findsOneWidget);
    });

    testWidgets('Part 1 counts the rent and the services', (tester) async {
      await pumpCompare(tester, settings: twoPayments);

      await tester.tap(segment('Part 1'));
      await tester.pumpAndSettle();

      expect(figure('43,500.00 ₽'), findsNWidgets(2));
      expect(figure('\u221234,500.00 ₽'), findsNWidgets(2));
      expect(figure('9,000.00 ₽'), findsNWidgets(2));
      // Nothing differs between the two months in Part 1.
      expect(figure('+0.00 ₽'), findsNWidgets(3));
    });

    testWidgets('Month goes back to the whole month', (tester) async {
      await pumpCompare(tester, settings: twoPayments);

      await tester.tap(segment('Part 2'));
      await tester.pumpAndSettle();
      await tester.tap(segment('Month'));
      await tester.pumpAndSettle();

      expect(find.text('Total after tax'), findsOneWidget);
      expect(find.text('Income before tax'), findsOneWidget);
    });

    testWidgets('the chosen part stays after the months are swapped', (
      tester,
    ) async {
      await pumpCompare(tester, settings: twoPayments);

      await tester.tap(segment('Part 2'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Swap months'));
      await tester.pumpAndSettle();

      // The pay and the balance both fall by the same amount.
      expect(figure('−4,350.00 ₽'), findsNWidgets(2));
    });

    testWidgets('the choice appears when the demo panel splits the months', (
      tester,
    ) async {
      final demo = await pumpCompare(tester);
      expect(find.byType(SegmentedButton<PeriodScope>), findsNothing);

      demo.update(demo.settings.copyWith(paymentMode: PaymentMode.twoPayments));
      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<PeriodScope>), findsOneWidget);
    });
  });

  group('large text', () {
    testWidgets('stacks each line so nothing is cut off', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpCompare(tester, size: const Size(412, 915));

      expect(tester.takeException(), isNull);
      // Every line names its own figures, so there is no heading row.
      expect(find.text('Line'), findsNothing);
      expect(find.text('Difference'), findsNWidgets(3));
      expect(figure('+4,350.00 ₽'), findsOneWidget);
    });

    testWidgets('keeps the columns at the normal size', (tester) async {
      await pumpCompare(tester, size: const Size(412, 915));

      expect(find.text('Line'), findsOneWidget);
      expect(find.text('Difference'), findsOneWidget);
    });
  });

  group('for a screen reader', () {
    testWidgets('each line is read with both months and the difference', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpCompare(tester);

      expect(
        find.bySemanticsLabel(
          amount(
            'Income before tax: September 2026 115,000.00 ₽, '
            'October 2026 120,000.00 ₽, difference +5,000.00 ₽',
          ),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a month with no salary is read as having none', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpCompare(tester);

      await tester.tap(find.byType(MonthChip).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jul'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          amount('Tax: September 2026 14,950.00 ₽, July 2026 No saved salary'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('loading, error and no connection', () {
    testWidgets('shows grey blocks while the months load', (tester) async {
      final demo = await pumpCompare(tester, size: const Size(412, 915));

      demo.update(demo.settings.copyWith(scenario: DemoScenario.loading));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SkeletonBox), findsWidgets);

      demo.update(const DemoSettings());
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonBox), findsNothing);
    });

    testWidgets('an error offers Try again, which loads the months', (
      tester,
    ) async {
      final demo = await pumpCompare(tester);

      demo.update(demo.settings.copyWith(scenario: DemoScenario.error));
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('no connection offers Try again', (tester) async {
      final demo = await pumpCompare(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.noConnection),
      );

      expect(find.text('No connection'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('an account with no saved month compares nothing', (
      tester,
    ) async {
      await pumpCompare(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(9));
    });
  });

  group('in Arabic', () {
    testWidgets('shows Arabic labels and Western digits', (tester) async {
      await pumpCompare(tester, language: AppLanguage.arabic);

      expect(find.text('مقارنة الأشهر'), findsOneWidget);
      expect(find.text('البند'), findsOneWidget);
      expect(find.text('الفرق'), findsOneWidget);
      expect(find.text('الدخل قبل الضريبة'), findsOneWidget);
      expect(find.text('الضريبة'), findsOneWidget);
      expect(find.textContaining(RegExp('[٠-٩]')), findsNothing);
      expect(find.byTooltip('تبديل الشهرين'), findsOneWidget);
    });

    testWidgets('mirrors the columns: the earlier month is on the right', (
      tester,
    ) async {
      await pumpCompare(tester, language: AppLanguage.arabic);

      final first = tester.getCenter(find.byType(MonthChip).first);
      final last = tester.getCenter(find.byType(MonthChip).last);
      expect(first.dx, greaterThan(last.dx));
    });

    testWidgets('compares the parts in Arabic', (tester) async {
      await pumpCompare(
        tester,
        language: AppLanguage.arabic,
        settings: twoPayments,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedButton<PeriodScope>),
          matching: find.text('الجزء 2'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الدفعة بعد الضريبة'), findsOneWidget);
    });
  });
}
