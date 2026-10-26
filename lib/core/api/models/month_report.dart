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

  /// Days 1 to 15; `null` for a month paid once.
  @JsonKey(name: 'first_part')
  final ReportSlice? firstPart;

  /// Day 16 to the end of the month; `null` for a month paid once.
  @JsonKey(name: 'second_part')
  final ReportSlice? secondPart;

  Map<String, Object?> toJson() => _$MonthReportToJson(this);
}
