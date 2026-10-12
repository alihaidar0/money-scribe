part of 'debt_details_bloc.dart';

sealed class DebtDetailsEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The screen opened: load the debt.
final class DebtDetailsStarted extends DebtDetailsEvent {
  const new();
}

/// The user pressed Try again.
final class DebtDetailsRetried extends DebtDetailsEvent {
  const new();
}

/// The debt may have changed: load it again.
final class DebtDetailsDataChanged extends DebtDetailsEvent {
  const new();
}

/// The user came back from the form that changes the debt: load it again
/// without showing the loading state.
final class DebtDetailsRefreshed extends DebtDetailsEvent {
  const new();
}

/// The user saved a new repayment.
final class RepaymentAdded extends DebtDetailsEvent {
  const new(this.draft);

  final RepaymentDraft draft;

  @override
  List<Object> get props => [draft];
}

/// The user saved changes to the repayment [id].
final class RepaymentChanged extends DebtDetailsEvent {
  const new(this.id, this.draft);

  final String id;
  final RepaymentDraft draft;

  @override
  List<Object> get props => [id, draft];
}

/// The user confirmed deleting the repayment [id].
final class RepaymentDeleted extends DebtDetailsEvent {
  const new(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

/// The user confirmed deleting the debt.
final class DebtDeleteRequested extends DebtDetailsEvent {
  const new();
}
