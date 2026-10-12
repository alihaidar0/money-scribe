part of 'salary_compare_bloc.dart';

sealed class SalaryCompareEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The comparison opened: load the saved months and choose the two newest.
final class SalaryCompareStarted extends SalaryCompareEvent {
  const new();
}

/// The user pressed Try again.
final class SalaryCompareRetried extends SalaryCompareEvent {
  const new();
}

/// The saved months may have changed: load them again.
final class SalaryCompareDataChanged extends SalaryCompareEvent {
  const new();
}

/// The user chose [month] for one of the two sides.
final class SalaryCompareMonthChosen extends SalaryCompareEvent {
  const new(this.side, this.month);

  final CompareSide side;
  final YearMonth month;

  @override
  List<Object> get props => [side, month];
}

/// The user pressed the swap button: the two months change sides.
final class SalaryCompareSwapped extends SalaryCompareEvent {
  const new();
}

/// The user chose to compare the whole month or one of its parts.
final class SalaryCompareScopeSelected extends SalaryCompareEvent {
  const new(this.scope);

  final PeriodScope scope;

  @override
  List<Object> get props => [scope];
}
