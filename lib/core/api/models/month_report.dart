// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'category_spend.dart';
import 'currency_enum.dart';
import 'report_slice.dart';

part 'month_report.g.dart';

/// The fields every month report has: the month, the currency, and what the month holds in any currency.
@JsonSerializable()
class MonthReport {
  const MonthReport({
    required this.month,
    required this.currency,
    required this.hasData,
    required this.currencies,
    required this.incomeTransactions,
    required this.purchases,
    required this.categories,
    required this.firstPart,
    required this.secondPart,
  });

  factory MonthReport.fromJson(Map<String, Object?> json) =>
      _$MonthReportFromJson(json);

  /// `YYYY-MM`.
  final String month;

  /// The currency of every amount.
  ///
  /// * `RUB` - RUB.
  /// * `USD` - USD.
  /// * `EUR` - EUR.
  /// * `GBP` - GBP.
  /// * `TRY` - TRY.
  /// * `SAR` - SAR.
  /// * `AED` - AED.
  /// * `EGP` - EGP.
  /// * `JPY` - JPY.
  /// * `KWD` - KWD.
  final CurrencyEnum currency;
  @JsonKey(name: 'has_data')
  final bool hasData;

  /// Every currency that has something in the month, ordered by code; the amounts are in `currency` only.
  final List<CurrencyEnum> currencies;

  /// Income transactions dated in the period. The salary and the recurring income are not included.
  @JsonKey(name: 'income_transactions')
  final Amount incomeTransactions;

  /// Expense transactions dated in the period. The fixed costs are not included.
  final Amount purchases;

  /// The spending by category (expense transactions only), the biggest `amount` first, ties by `category_id`; the amounts add up to `purchases`.
  final List<CategorySpend> categories;

  /// From the first pay day to the day before the second pay day of the next month (the 20th to the 4th with 20 and 5); `null` for a month paid once.
  @JsonKey(name: 'first_part')
  final ReportSlice? firstPart;

  /// From the second pay day of the next month to the day before the next first pay day (the 5th to the 19th with 20 and 5); `null` for a month paid once.
  @JsonKey(name: 'second_part')
  final ReportSlice? secondPart;

  Map<String, Object?> toJson() => _$MonthReportToJson(this);
}
