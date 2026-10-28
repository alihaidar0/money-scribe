import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/salary/data/fake/salary_seed.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';

/// Invented fixed items for the fake server: the months that have a saved
/// salary have the same three. Never the owner's real figures.
abstract final class FixedItemsSeed {
  static Money _rub(int rubles) => Money(rubles * 100, Currency.rub);

  /// The fixed items of [month]: a scholarship in the second part, and the
  /// rent and the services in the first. None for a month outside
  /// [SalarySeed.months].
  static List<FixedItem> items(YearMonth month) {
    if (!SalarySeed.months.contains(month)) return const [];
    return [
      FixedItem(
        id: 'seed-${month.param}-scholarship',
        name: 'Scholarship',
        amount: _rub(5000),
        kind: FixedItemKind.income,
        part: FixedItemPart.second,
        day: 8,
      ),
      FixedItem(
        id: 'seed-${month.param}-rent',
        name: 'Rent',
        amount: _rub(30000),
        kind: FixedItemKind.expense,
        part: FixedItemPart.first,
        day: 1,
      ),
      FixedItem(
        id: 'seed-${month.param}-services',
        name: 'Services',
        amount: _rub(4500),
        kind: FixedItemKind.expense,
        part: FixedItemPart.first,
        day: 21,
      ),
    ];
  }
}
