import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

/// A repayment as it is typed, before the server gives it an id.
///
/// A [date] is a calendar day: its time of day is always midnight.
final class RepaymentDraft extends Equatable {
  const new({required this.amount, required this.date});

  /// The draft of what was typed, or `null` while the amount is not a positive
  /// number, or is more than [maxAmount] (what is still to be repaid).
  static RepaymentDraft? tryCreate({
    required String amount,
    required Currency currency,
    required DateTime date,
    required Money maxAmount,
  }) {
    final money = Money.tryParse(amount, currency);
    if (money == null || !money.isPositive || money > maxAmount) return null;
    return RepaymentDraft(amount: money, date: _day(date));
  }

  final Money amount;
  final DateTime date;

  @override
  List<Object> get props => [amount, date];
}

/// A part of a debt that was paid back.
final class Repayment extends Equatable {
  const new({required this.id, required this.amount, required this.date});

  new fromDraft(this.id, RepaymentDraft draft)
    : amount = draft.amount,
      date = draft.date;

  final String id;
  final Money amount;
  final DateTime date;

  /// What the repayment is made of, to edit it.
  RepaymentDraft get draft => RepaymentDraft(amount: amount, date: date);

  @override
  List<Object> get props => [id, amount, date];
}

/// A debt as it is typed, before the server gives it an id.
final class DebtDraft extends Equatable {
  const new({
    required this.direction,
    required this.person,
    required this.amount,
    required this.startDate,
    this.dueDate,
    this.note = '',
  });

  /// The most characters a person's name has.
  static const maxPersonLength = 50;

  /// The most characters a note has.
  static const maxNoteLength = 100;

  /// The draft of what was typed, or `null` while the person is missing or
  /// too long, the amount is not a positive number, the note is too long, or
  /// the debt is due before it starts.
  static DebtDraft? tryCreate({
    required DebtDirection direction,
    required String person,
    required String amount,
    required Currency currency,
    required DateTime startDate,
    DateTime? dueDate,
    String note = '',
  }) {
    final name = person.trim();
    final money = Money.tryParse(amount, currency);
    final start = _day(startDate);
    final due = dueDate == null ? null : _day(dueDate);
    if (name.isEmpty ||
        name.length > maxPersonLength ||
        money == null ||
        !money.isPositive ||
        note.trim().length > maxNoteLength ||
        (due != null && due.isBefore(start))) {
      return null;
    }
    return DebtDraft(
      direction: direction,
      person: name,
      amount: money,
      startDate: start,
      dueDate: due,
      note: note.trim(),
    );
  }

  final DebtDirection direction;
  final String person;

  /// What was lent or borrowed, always positive.
  final Money amount;
  final DateTime startDate;
  final DateTime? dueDate;
  final String note;

  @override
  List<Object?> get props => [
    direction,
    person,
    amount,
    startDate,
    dueDate,
    note,
  ];
}

/// Money lent to someone or borrowed from someone, with what was paid back.
final class Debt extends Equatable {
  const new({
    required this.id,
    required this.direction,
    required this.person,
    required this.amount,
    required this.startDate,
    this.dueDate,
    this.note = '',
    this.repayments = const [],
  });

  final String id;
  final DebtDirection direction;
  final String person;

  /// What was lent or borrowed, always positive.
  final Money amount;
  final DateTime startDate;
  final DateTime? dueDate;
  final String note;

  /// The repayments, in the order they were added.
  final List<Repayment> repayments;

  /// What was paid back so far.
  Money get repaid {
    return repayments.fold<Money>(
      Money.zero(amount.currency),
      (sum, repayment) => sum + repayment.amount,
    );
  }

  /// What is still to be repaid; never below nothing.
  Money get remaining {
    final left = amount - repaid;
    return left.isNegative ? Money.zero(amount.currency) : left;
  }

  /// Whether everything was paid back.
  bool get isSettled => remaining.isZero;

  /// How much of the debt was paid back, from 0 to 1.
  double get progress {
    if (amount.minorUnits == 0) return 1;
    final ratio = repaid.minorUnits / amount.minorUnits;
    return ratio.clamp(0, 1).toDouble();
  }

  /// Where the debt stands on the day [today]: settled, overdue once its due
  /// day has passed with something left to repay, or open.
  DebtStatus statusOn(DateTime today) {
    if (isSettled) return DebtStatus.settled;
    final due = dueDate;
    if (due != null && due.isBefore(_day(today))) return DebtStatus.overdue;
    return DebtStatus.open;
  }

  /// What the debt is made of, to edit it.
  DebtDraft get draft {
    return DebtDraft(
      direction: direction,
      person: person,
      amount: amount,
      startDate: startDate,
      dueDate: dueDate,
      note: note,
    );
  }

  /// This debt with what [draft] says; its repayments stay.
  Debt withDraft(DebtDraft draft) {
    return Debt(
      id: id,
      direction: draft.direction,
      person: draft.person,
      amount: draft.amount,
      startDate: draft.startDate,
      dueDate: draft.dueDate,
      note: draft.note,
      repayments: repayments,
    );
  }

  /// This debt with [repayments] instead of its own.
  Debt withRepayments(List<Repayment> repayments) {
    return Debt(
      id: id,
      direction: direction,
      person: person,
      amount: amount,
      startDate: startDate,
      dueDate: dueDate,
      note: note,
      repayments: repayments,
    );
  }

  @override
  List<Object?> get props => [
    id,
    direction,
    person,
    amount,
    startDate,
    dueDate,
    note,
    repayments,
  ];
}
