import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/salary/data/fake/fixed_items_seed.dart';
import 'package:money_scribe/features/salary/data/fake/salary_seed.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/domain/salary_comparison.dart';
import 'package:money_scribe/features/salary/domain/salary_history_entry.dart';
import 'package:money_scribe/features/salary/domain/salary_inputs.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

const september = YearMonth(2026, 9);
const october = YearMonth(2026, 10);

SalaryHistoryEntry entry(YearMonth month, PaymentMode mode) {
  return SalaryHistoryEntry.tryFrom(SalarySeed.month(month, mode)!)!;
}

/// The September salary of the seed, paid in dollars.
SalaryHistoryEntry dollarEntry() {
  final inputs = SalarySeed.month(september, PaymentMode.onePayment)!.inputs;
  return SalaryHistoryEntry.tryFrom(
    SalaryMonth(
      month: september,
      inputs: SalaryInputs(
        baseSalary: Money(inputs.baseSalary.minorUnits, Currency.usd),
        foodPerDay: Money(inputs.foodPerDay.minorUnits, Currency.usd),
        workingDaysInMonth: inputs.workingDaysInMonth,
        workingHoursInMonth: inputs.workingHoursInMonth,
        extraHoursHundredths: inputs.extraHoursHundredths,
        taxRateBasisPoints: inputs.taxRateBasisPoints,
      ),
      firstPayDay: 20,
      secondPayDay: 5,
    ),
  )!;
}

void main() {
  final oneSeptember = entry(september, PaymentMode.onePayment);
  final oneOctober = entry(october, PaymentMode.onePayment);
  final twoSeptember = entry(september, PaymentMode.twoPayments);
  final twoOctober = entry(october, PaymentMode.twoPayments);

  group('the whole month', () {
    test('compares income, tax and the total after tax', () {
      final lines = SalaryComparison.lines(
        oneSeptember,
        oneOctober,
        PeriodScope.month,
      );

      expect(lines.map((line) => line.kind), [
        ComparisonLineKind.incomeBeforeTax,
        ComparisonLineKind.tax,
        ComparisonLineKind.totalAfterTax,
      ]);
      expect(lines.map((line) => line.left), [
        rub(115000),
        rub(14950),
        rub(100050),
      ]);
      expect(lines.map((line) => line.right), [
        rub(120000),
        rub(15600),
        rub(104400),
      ]);
    });

    test('the difference is the right figure minus the left one', () {
      final lines = SalaryComparison.lines(
        oneSeptember,
        oneOctober,
        PeriodScope.month,
      );

      expect(lines.map((line) => line.difference), [
        rub(5000),
        rub(650),
        rub(4350),
      ]);
    });

    test('swapping the months turns the difference around', () {
      final lines = SalaryComparison.lines(
        oneOctober,
        oneSeptember,
        PeriodScope.month,
      );

      expect(lines.last.difference, -rub(4350));
    });

    test('the same month on both sides differs by nothing', () {
      final lines = SalaryComparison.lines(
        oneOctober,
        oneOctober,
        PeriodScope.month,
      );

      expect(lines.map((line) => line.difference?.isZero), everyElement(true));
    });
  });

  group('a part', () {
    final septemberItems = FixedItemsSeed.items(september);
    final octoberItems = FixedItemsSeed.items(october);

    List<ComparisonLine> part(
      PeriodScope scope, {
      SalaryHistoryEntry? left,
      SalaryHistoryEntry? right,
      List<FixedItem>? leftItems,
      List<FixedItem>? rightItems,
    }) {
      return SalaryComparison.lines(
        left ?? twoSeptember,
        right ?? twoOctober,
        scope,
        leftItems: leftItems ?? septemberItems,
        rightItems: rightItems ?? octoberItems,
      );
    }

    test('compares the pay, the fixed items and the balance they leave', () {
      final lines = part(PeriodScope.secondPart);

      expect(lines.map((line) => line.kind), [
        ComparisonLineKind.payAfterTax,
        ComparisonLineKind.fixedItems,
        ComparisonLineKind.balanceAfterFixedItems,
      ]);
      expect(lines.map((line) => line.left), [
        rub(56550),
        rub(5000),
        rub(61550),
      ]);
      expect(lines.map((line) => line.right), [
        rub(60900),
        rub(5000),
        rub(65900),
      ]);
      expect(lines.map((line) => line.difference), [
        rub(4350),
        rub(0),
        rub(4350),
      ]);
    });

    test('the first part counts the items that belong to it', () {
      final lines = part(PeriodScope.firstPart);

      expect(lines.map((line) => line.left), [
        rub(43500),
        rub(-34500),
        rub(9000),
      ]);
      expect(lines.map((line) => line.right), [
        rub(43500),
        rub(-34500),
        rub(9000),
      ]);
      expect(lines.map((line) => line.difference?.isZero), everyElement(true));
    });

    test('a month with other items shows how they differ', () {
      final lines = part(
        PeriodScope.firstPart,
        rightItems: [
          ...octoberItems,
          FixedItem(
            id: 'gym',
            name: 'Gym',
            amount: rub(1200),
            kind: FixedItemKind.expense,
            part: FixedItemPart.first,
          ),
        ],
      );

      expect(lines[1].difference, rub(-1200));
      expect(lines[2].difference, rub(-1200));
      expect(lines[0].difference, rub(0));
    });

    test('a month with no item in the part has nothing fixed', () {
      final lines = part(PeriodScope.secondPart, leftItems: const []);

      expect(lines[1].left, rub(0));
      expect(lines[2].left, rub(56550));
    });

    test('while the items are not known only the pay has a figure', () {
      final lines = SalaryComparison.lines(
        twoSeptember,
        twoOctober,
        PeriodScope.secondPart,
      );

      expect(lines[0].left, rub(56550));
      expect(lines[1].left, isNull);
      expect(lines[2].left, isNull);
      expect(lines[2].difference, isNull);
    });

    test('a month paid in one payment has no parts', () {
      final lines = part(PeriodScope.firstPart, left: oneSeptember);

      for (final line in lines) {
        expect(line.left, isNull, reason: '${line.kind}');
        expect(line.difference, isNull, reason: '${line.kind}');
      }
      expect(lines.first.right, rub(43500));
    });
  });

  group('a month with no figures', () {
    test('has no figure and no difference on any line', () {
      final lines = SalaryComparison.lines(null, oneOctober, PeriodScope.month);

      expect(lines.map((line) => line.left), everyElement(isNull));
      expect(lines.map((line) => line.right), everyElement(isNotNull));
      expect(lines.map((line) => line.difference), everyElement(isNull));
    });

    test('two months that are not saved compare to nothing', () {
      final lines = SalaryComparison.lines(null, null, PeriodScope.month);

      expect(lines, hasLength(3));
      expect(lines.map((line) => line.difference), everyElement(isNull));
    });
  });

  test('months in different currencies are not subtracted', () {
    final lines = SalaryComparison.lines(
      dollarEntry(),
      oneOctober,
      PeriodScope.month,
    );

    expect(lines.first.left, isNotNull);
    expect(lines.first.right, isNotNull);
    expect(lines.first.difference, isNull);
  });

  group('hasParts', () {
    test('is true when either month is paid in two payments', () {
      expect(SalaryComparison.hasParts(twoSeptember, twoOctober), isTrue);
      expect(SalaryComparison.hasParts(oneSeptember, twoOctober), isTrue);
      expect(SalaryComparison.hasParts(twoSeptember, null), isTrue);
    });

    test('is false when no month is paid in two payments', () {
      expect(SalaryComparison.hasParts(oneSeptember, oneOctober), isFalse);
      expect(SalaryComparison.hasParts(null, oneOctober), isFalse);
      expect(SalaryComparison.hasParts(null, null), isFalse);
    });
  });
}
