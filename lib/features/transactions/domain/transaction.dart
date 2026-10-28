import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';

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
    this.part,
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
    PayPart? part,
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
      // Only an income joins a part.
      part: kind == TransactionKind.income ? part : null,
    );
  }

  /// Always positive: [kind] says which way it goes.
  final Money amount;
  final TransactionKind kind;
  final DateTime date;
  final String categoryId;
  final String accountId;
  final String note;

  /// The payment of a month paid in two payments an income joins, when the
  /// person chose it; `null` for the one whose pay day is nearest to the
  /// [date], and for an expense.
  final PayPart? part;

  @override
  List<Object?> get props => [
    amount,
    kind,
    date,
    categoryId,
    accountId,
    note,
    part,
  ];
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
    this.part,
    this.version = 1,
  });

  /// The transaction a [draft] becomes. [joined] is the payment an income
  /// joins when the draft does not say (the one nearest to its date).
  new fromDraft(
    this.id,
    TransactionDraft draft, {
    this.version = 1,
    PayPart? joined,
  }) : amount = draft.amount,
       kind = draft.kind,
       date = draft.date,
       categoryId = draft.categoryId,
       accountId = draft.accountId,
       note = draft.note,
       part = draft.kind == TransactionKind.income
           ? draft.part ?? joined
           : null;

  final String id;

  /// Always positive: [kind] says which way it goes.
  final Money amount;
  final TransactionKind kind;
  final DateTime date;
  final String categoryId;
  final String accountId;
  final String note;

  /// The payment of a month paid in two payments an income joins: the one the
  /// person chose, or else the one whose pay day is nearest to the [date].
  /// `null` for an expense.
  final PayPart? part;

  /// The version of the record on the server, sent back with a change or a
  /// delete so a change made on another device in between is never
  /// overwritten.
  final int version;

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
      part: part,
    );
  }

  @override
  List<Object?> get props => [
    id,
    amount,
    kind,
    date,
    categoryId,
    accountId,
    note,
    part,
    version,
  ];
}

/// Why the server did not accept a transaction the person typed.
enum TransactionRefusal {
  /// The person has as many transactions as the server allows.
  limitReached,

  /// The chosen category does not take this kind of transaction (an expense in
  /// a category for income).
  categoryNotAllowed,

  /// The chosen category or account does not exist any more: it was deleted
  /// on another device.
  categoryOrAccountGone,

  /// The date is outside the years the server keeps (2000 to 2099).
  dateOutOfRange,
}

/// Thrown when the server refuses a transaction for a reason the person can
/// act on.
final class TransactionRefusedException implements Exception {
  const new(this.refusal);

  final TransactionRefusal refusal;

  @override
  String toString() => 'TransactionRefusedException($refusal)';
}
