part of 'debt_form_bloc.dart';

sealed class DebtFormEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The form opened: with an id, load the debt to be changed.
final class DebtFormStarted extends DebtFormEvent {
  const new();
}

/// The user pressed Try again.
final class DebtFormRetried extends DebtFormEvent {
  const new();
}

/// The user chose "I lent" or "I borrowed".
final class DebtDirectionSelected extends DebtFormEvent {
  const new(this.direction);

  final DebtDirection direction;

  @override
  List<Object?> get props => [direction];
}

/// The user typed the person.
final class DebtPersonChanged extends DebtFormEvent {
  const new(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// The user typed the amount.
final class DebtAmountChanged extends DebtFormEvent {
  const new(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// The user chose the start day.
final class DebtStartDateChosen extends DebtFormEvent {
  const new(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

/// The user chose the due day.
final class DebtDueDateChosen extends DebtFormEvent {
  const new(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

/// The user took the due day away.
final class DebtDueDateCleared extends DebtFormEvent {
  const new();
}

/// The user typed the note.
final class DebtNoteChanged extends DebtFormEvent {
  const new(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// The user pressed Save.
final class DebtSaveRequested extends DebtFormEvent {
  const new();
}
