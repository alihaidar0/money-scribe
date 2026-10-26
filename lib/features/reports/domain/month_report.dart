import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/reports/domain/period_report.dart';

/// The report of one month: the whole month, and for a month paid in two
/// payments each part of it too.
final class MonthReport extends Equatable {
  const new({
    required this.month,
    required this.total,
    this.firstPart,
    this.secondPart,
    this.hasOtherCurrencies = false,
  }) : assert(
         (firstPart == null) == (secondPart == null),
         'A month has both parts or none',
       );

  final YearMonth month;

  /// The whole month.
  final PeriodReport total;

  /// The 1st-15th, for a month paid in two payments.
  final PeriodReport? firstPart;

  /// The 16th-end, for a month paid in two payments.
  final PeriodReport? secondPart;

  /// Whether the month has records in a currency other than the one reported.
  /// They are not in the figures.
  final bool hasOtherCurrencies;

  /// Whether the month is paid in two payments.
  bool get hasParts => firstPart != null;

  /// The report of [scope]. A month without parts only has the whole month.
  PeriodReport reportOf(PeriodScope scope) {
    return switch (scope) {
      PeriodScope.month => total,
      PeriodScope.firstPart => firstPart ?? total,
      PeriodScope.secondPart => secondPart ?? total,
    };
  }

  @override
  List<Object?> get props => [
    month,
    total,
    firstPart,
    secondPart,
    hasOtherCurrencies,
  ];
}
