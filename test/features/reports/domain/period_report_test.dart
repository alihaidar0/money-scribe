import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/reports/domain/category_spend.dart';
import 'package:money_scribe/features/reports/domain/period_report.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

CategorySpend spend(String id, int rubles) {
  return CategorySpend(
    categoryId: id,
    name: id,
    icon: CategoryIcon.other,
    amount: rub(rubles),
  );
}

PeriodReport report(List<CategorySpend> categories) {
  return PeriodReport(
    income: rub(100),
    spent: categories.fold(
      const Money.zero(Currency.rub),
      (sum, category) => sum + category.amount,
    ),
    categories: categories,
  );
}

void main() {
  group('PeriodReport', () {
    test('adds up what the categories come to', () {
      final period = report([spend('a', 30000), spend('b', 9800)]);

      expect(period.categoriesTotal, rub(39800));
    });

    test('has a share in tenths of a percent', () {
      final period = report([
        spend('housing', 30000),
        spend('groceries', 9800),
        spend('utilities', 4500),
        spend('transport', 3400),
        spend('dining', 3150),
        spend('other', 1900),
      ]);

      expect(
        [for (final category in period.categories) period.permilleOf(category)],
        [569, 186, 85, 64, 60, 36],
      );
    });

    test('rounds a share half up', () {
      // 1 of 8 is exactly 12.5 per mille: 13.
      final period = report([spend('a', 1), spend('b', 7)]);

      expect(period.permilleOf(period.categories.first), 125);
      final third = report([spend('a', 1), spend('b', 2)]);
      expect(third.permilleOf(third.categories.first), 333);
      expect(third.permilleOf(third.categories.last), 667);
    });

    test('has no share when nothing is spent', () {
      final period = report([spend('a', 0)]);

      expect(period.permilleOf(period.categories.first), 0);
    });
  });

  group('CategorySpend.fixedCosts', () {
    test('is the slice of the fixed costs, not a category', () {
      final slice = CategorySpend.fixedCosts(rub(8000));

      expect(slice.isFixedCosts, isTrue);
      expect(slice.categoryId, isEmpty);
      expect(slice.key, isNull);
      expect(slice.amount, rub(8000));
    });

    test('counts in the share of the spending like any category', () {
      final period = PeriodReport(
        income: rub(20000),
        spent: rub(10000),
        categories: [CategorySpend.fixedCosts(rub(7500)), spend('food', 2500)],
      );

      expect(period.permilleOf(period.categories.first), 750);
    });

    test('is not equal to a category of the same amount', () {
      expect(CategorySpend.fixedCosts(rub(100)), isNot(spend('x', 100)));
    });
  });
}
