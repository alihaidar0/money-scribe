import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/reports/domain/category_spend.dart';
import 'package:money_scribe/features/reports/domain/debts_report.dart';
import 'package:money_scribe/features/reports/domain/month_report.dart';
import 'package:money_scribe/features/reports/domain/period_report.dart';

/// Invented figures for the fake server. October 2026 and September 2026 are
/// the examples of `docs/stitch-prompts.md`; other months follow one of four
/// patterns so switching month visibly changes the screen. Never the owner's
/// real figures.
abstract final class ReportsSeed {
  static Money _rub(int rubles) => Money(rubles * 100, Currency.rub);

  /// The categories, in the order the seed lists them below.
  static const Map<String, (String, CategoryIcon)> _names = {
    'housing': ('Housing', CategoryIcon.housing),
    'groceries': ('Groceries', CategoryIcon.groceries),
    'utilities': ('Utilities', CategoryIcon.utilities),
    'transport': ('Transport', CategoryIcon.transport),
    'dining': ('Dining', CategoryIcon.dining),
    'other': ('Other', CategoryIcon.other),
  };

  /// Each pattern is the income and the spending (in whole rubles by
  /// category) of the first part and of the second part of a month.
  /// October 2026 is pattern 2 and September 2026 pattern 1, as in the
  /// Overview.
  static const _patterns = [
    _Pattern(
      firstIncome: 43500,
      secondIncome: 61550,
      first: {
        'housing': 30000,
        'groceries': 3900,
        'utilities': 4400,
        'transport': 1500,
        'dining': 1100,
        'other': 800,
      },
      second: {
        'groceries': 5100,
        'transport': 1700,
        'dining': 1300,
        'other': 900,
      },
    ),
    _Pattern(
      firstIncome: 43500,
      secondIncome: 61550,
      first: {
        'housing': 30000,
        'groceries': 5000,
        'utilities': 4800,
        'transport': 2500,
        'dining': 1700,
        'other': 1300,
      },
      second: {
        'groceries': 5900,
        'transport': 1800,
        'dining': 1950,
        'other': 1000,
      },
    ),
    _Pattern(
      firstIncome: 43500,
      secondIncome: 65900,
      first: {
        'housing': 30000,
        'groceries': 4200,
        'utilities': 4500,
        'transport': 1800,
        'dining': 1200,
        'other': 1050,
      },
      second: {
        'groceries': 5600,
        'transport': 1600,
        'dining': 1950,
        'other': 850,
      },
    ),
    _Pattern(
      firstIncome: 43500,
      secondIncome: 65900,
      first: {
        'housing': 30000,
        'groceries': 4600,
        'utilities': 4200,
        'transport': 2000,
        'dining': 1500,
        'other': 900,
      },
      second: {
        'groceries': 6200,
        'transport': 1400,
        'dining': 2100,
        'other': 700,
      },
    ),
  ];

  static MonthReport month(YearMonth month, PaymentMode mode) {
    final pattern = _patterns[(month.year * 12 + month.month) % 4];
    final first = _period(pattern.firstIncome, pattern.first);
    final second = _period(pattern.secondIncome, pattern.second);
    final total = _period(pattern.firstIncome + pattern.secondIncome, {
      for (final id in _names.keys)
        if ((pattern.first[id] ?? 0) + (pattern.second[id] ?? 0) > 0)
          id: (pattern.first[id] ?? 0) + (pattern.second[id] ?? 0),
    });

    return switch (mode) {
      PaymentMode.onePayment => MonthReport(month: month, total: total),
      PaymentMode.twoPayments => MonthReport(
        month: month,
        total: total,
        firstPart: first,
        secondPart: second,
      ),
    };
  }

  static PeriodReport _period(int income, Map<String, int> spending) {
    final categories = [
      for (final MapEntry(key: id, value: rubles) in spending.entries)
        if (rubles > 0)
          CategorySpend(
            categoryId: id,
            key: id,
            name: _names[id]!.$1,
            icon: _names[id]!.$2,
            amount: _rub(rubles),
          ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    return PeriodReport(
      income: _rub(income),
      spent: categories.fold<Money>(
        const Money.zero(Currency.rub),
        (sum, category) => sum + category.amount,
      ),
      categories: categories,
    );
  }

  /// The debts of `DebtsSeed` of the Debts feature, as the report lists them.
  static DebtsReport debts() {
    return DebtsReport(
      owedToYou: _rub(8500),
      youOwe: _rub(0),
      overdue: [
        DebtReportItem(
          id: 'maria',
          person: 'Maria',
          direction: DebtDirection.lent,
          remaining: _rub(2500),
          status: DebtStatus.overdue,
          dueDate: DateTime(2026, 9, 30),
        ),
      ],
      open: [
        DebtReportItem(
          id: 'sam',
          person: 'Sam',
          direction: DebtDirection.lent,
          remaining: _rub(6000),
          status: DebtStatus.open,
          dueDate: DateTime(2026, 10, 31),
        ),
      ],
    );
  }
}

class _Pattern {
  const new({
    required this.firstIncome,
    required this.secondIncome,
    required this.first,
    required this.second,
  });

  final int firstIncome;
  final int secondIncome;
  final Map<String, int> first;
  final Map<String, int> second;
}
