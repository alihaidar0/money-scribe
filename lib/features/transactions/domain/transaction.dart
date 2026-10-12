import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';

/// Whether a transaction brings money in or takes it out.
enum TransactionKind { expense, income }

/// A transaction as it is typed, before the server gives it an id.
///
/// A [date] is a calendar day: its time of day is always midnight and means
/// nothing.
final class TransactionDraft extends Equatable {
  const new({
    required this.amount,
    required this.kind,
    required this.date,
    required this.categoryId,
    required this.accountId,
    this.note = '',
  });

  /// The most characters a note has.
  static const maxNoteLength = 100;

  /// The draft of what was typed, or `null` while the amount is not a positive
  /// number, no category or account is chosen, or the note is too long.
  static TransactionDraft? tryCreate({
    required String amount,
    required Currency currency,
    required TransactionKind kind,
    required DateTime date,
    required String? categoryId,
    required String? accountId,
    String note = '',
  }) {
    final money = Money.tryParse(amount, currency);
    final trimmed = note.trim();
    if (money == null ||
        !money.isPositive ||
        categoryId == null ||
        accountId == null ||
        trimmed.length > maxNoteLength) {
      return null;
    }
    return TransactionDraft(
      amount: money,
      kind: kind,
      date: DateTime(date.year, date.month, date.day),
      categoryId: categoryId,
      accountId: accountId,
      note: trimmed,
    );
  }

  /// Always positive: [kind] says which way it goes.
  final Money amount;
  final TransactionKind kind;
  final DateTime date;
  final String categoryId;
  final String accountId;
  final String note;

  @override
  List<Object> get props => [amount, kind, date, categoryId, accountId, note];
}

/// A transaction, as the server holds it.
final class Transaction extends Equatable {
  const new({
    required this.id,
    required this.amount,
    required this.kind,
    required this.date,
    required this.categoryId,
    required this.accountId,
    this.note = '',
  });

  new fromDraft(this.id, TransactionDraft draft)
    : amount = draft.amount,
      kind = draft.kind,
      date = draft.date,
      categoryId = draft.categoryId,
      accountId = draft.accountId,
      note = draft.note;

  final String id;

  /// Always positive: [kind] says which way it goes.
  final Money amount;
  final TransactionKind kind;
  final DateTime date;
  final String categoryId;
  final String accountId;
  final String note;

  /// The amount with its sign: positive for income, negative for an expense.
  Money get signedAmount => kind == TransactionKind.income ? amount : -amount;

  /// What the transaction is made of, to edit it.
  TransactionDraft get draft {
    return TransactionDraft(
      amount: amount,
      kind: kind,
      date: date,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
    );
  }

  @override
  List<Object> get props => [
    id,
    amount,
    kind,
    date,
    categoryId,
    accountId,
    note,
  ];
}
