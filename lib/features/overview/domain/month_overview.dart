import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/overview/domain/overview_figures.dart';

/// The overview of one month: its figures, and for a month paid in two
/// payments the figures of each part too.
final class MonthOverview extends Equatable {
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
  final OverviewFigures total;

  /// The 1st-15th, for a month paid in two payments.
  final OverviewFigures? firstPart;

  /// The 16th-end, for a month paid in two payments.
  final OverviewFigures? secondPart;

  /// Whether the month has records in a currency other than the one of the
  /// figures. They are not in the figures: amounts of two currencies are never
  /// added.
  final bool hasOtherCurrencies;

  /// Whether the month is paid in two payments.
  bool get hasParts => firstPart != null;

  /// The figures of [scope]. A month without parts only has the whole month.
  OverviewFigures figuresOf(PeriodScope scope) {
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
