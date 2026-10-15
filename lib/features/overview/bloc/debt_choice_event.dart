part of 'debt_choice_bloc.dart';

sealed class DebtChoiceEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The sheet opened, or the user pressed Try again: load the debts.
final class DebtChoiceStarted extends DebtChoiceEvent {
  const new();
}
