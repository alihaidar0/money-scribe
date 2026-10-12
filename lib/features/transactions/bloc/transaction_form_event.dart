part of 'transaction_form_bloc.dart';

sealed class TransactionFormEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The form opened: load what it offers, and with an id the transaction.
final class TransactionFormStarted extends TransactionFormEvent {
  const new();
}

/// The user pressed Try again.
final class TransactionFormRetried extends TransactionFormEvent {
  const new();
}

/// The user chose Expense or Income.
final class TransactionKindSelected extends TransactionFormEvent {
  const new(this.kind);

  final TransactionKind kind;

  @override
  List<Object?> get props => [kind];
}

/// The user typed the amount.
final class TransactionAmountChanged extends TransactionFormEvent {
  const new(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// The user chose the day.
final class TransactionDateChosen extends TransactionFormEvent {
  const new(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

/// The user chose a category.
final class TransactionCategoryChosen extends TransactionFormEvent {
  const new(this.categoryId);

  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}

/// The user chose an account.
final class TransactionAccountChosen extends TransactionFormEvent {
  const new(this.accountId);

  final String accountId;

  @override
  List<Object?> get props => [accountId];
}

/// The user typed the note.
final class TransactionNoteChanged extends TransactionFormEvent {
  const new(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// The user pressed Save.
final class TransactionSaveRequested extends TransactionFormEvent {
  const new();
}

/// The user confirmed deleting the transaction.
final class TransactionDeleteRequested extends TransactionFormEvent {
  const new();
}
