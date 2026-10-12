part of 'reports_bloc.dart';

sealed class ReportsEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The Reports screen opened: load the month of today.
final class ReportsStarted extends ReportsEvent {
  const new();
}

/// The user pressed Try again.
final class ReportsRetried extends ReportsEvent {
  const new();
}

/// What the reports are made of may have changed: load them again.
final class ReportsDataChanged extends ReportsEvent {
  const new();
}

/// The user chose a segment: Categories, Month vs month or Debts.
final class ReportsViewSelected extends ReportsEvent {
  const new(this.view);

  final ReportsView view;

  @override
  List<Object> get props => [view];
}

/// The user chose the whole month or one of its parts.
final class ReportsScopeSelected extends ReportsEvent {
  const new(this.scope);

  final PeriodScope scope;

  @override
  List<Object> get props => [scope];
}

/// The user chose a month in the month picker.
final class ReportsMonthSelected extends ReportsEvent {
  const new(this.month);

  final YearMonth month;

  @override
  List<Object> get props => [month];
}

/// The user chose the month to compare with, in the month comparison.
final class ReportsCompareMonthSelected extends ReportsEvent {
  const new(this.month);

  final YearMonth month;

  @override
  List<Object> get props => [month];
}
