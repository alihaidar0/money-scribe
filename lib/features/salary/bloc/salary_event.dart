part of 'salary_bloc.dart';

sealed class SalaryEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The Salary screen opened: load the month of today.
final class SalaryStarted extends SalaryEvent {
  const new();
}

/// The user chose another month in the month picker.
final class SalaryMonthSelected extends SalaryEvent {
  const new(this.month);

  final YearMonth month;

  @override
  List<Object> get props => [month];
}

/// The user typed in one of the input fields.
final class SalaryFieldChanged extends SalaryEvent {
  const new(this.field, this.value);

  final SalaryField field;

  /// What the field holds now.
  final String value;

  @override
  List<Object> get props => [field, value];
}

/// The user chose one payment or two payments a month (after confirming, for
/// a month that was saved).
final class SalaryPaymentModeSelected extends SalaryEvent {
  const new(this.mode);

  final PaymentMode mode;

  @override
  List<Object> get props => [mode];
}

/// The user pressed Save month.
final class SalarySaveRequested extends SalaryEvent {
  const new();
}

/// The user pressed Try again.
final class SalaryRetried extends SalaryEvent {
  const new();
}

/// The saved months may have changed: load the month again.
final class SalaryDataChanged extends SalaryEvent {
  const new();
}
