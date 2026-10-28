import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/core/payments/period_scope.dart';

/// Whether a fixed item adds to the month or takes from it.
enum FixedItemKind { income, expense }

/// Which payment of a month paid in two payments a fixed item belongs to. A
/// month paid in one payment ignores it.
enum FixedItemPart {
  first,
  second;

  /// The part a fixed item dated [day] of the month is paid from, by the rule
  /// of [PayCycle]: what is spent on a day comes out of the payment received
  /// most recently, counting back over the turn of the month. With the first
  /// payment on the 20th and the second on the 5th, the 5th to the 19th is the
  /// second part and the 20th to the 4th of the next month the first.
  static FixedItemPart ofDay(
    int day, {
    required int firstPayDay,
    required int secondPayDay,
  }) {
    final cycle = PayCycle.twoPayments(
      firstPayDay: firstPayDay,
      secondPayDay: secondPayDay,
    );
    return cycle.partOfDay(day) == PeriodScope.secondPart ? second : first;
  }
}

/// A fixed item as it is typed, before the server gives it an id: a recurring
/// income or cost of a month, such as a scholarship or the rent.
final class FixedItemDraft extends Equatable {
  const new({
    required this.name,
    required this.amount,
    required this.kind,
    this.part = FixedItemPart.first,
    this.day,
  });

  /// The most characters a name has.
  static const maxNameLength = 50;

  /// The draft of what was typed, or `null` while the name is empty or too
  /// long, or the amount is not a positive number.
  static FixedItemDraft? tryCreate({
    required String name,
    required String amount,
    required Currency currency,
    required FixedItemKind kind,
    FixedItemPart part = FixedItemPart.first,
    int? day,
  }) {
    final trimmed = name.trim();
    final money = Money.tryParse(amount, currency);
    if (trimmed.isEmpty ||
        trimmed.length > maxNameLength ||
        money == null ||
        !money.isPositive) {
      return null;
    }
    return FixedItemDraft(
      name: trimmed,
      amount: money,
      kind: kind,
      part: part,
      day: day,
    );
  }

  final String name;

  /// Always positive: [kind] says which way it goes.
  final Money amount;
  final FixedItemKind kind;
  final FixedItemPart part;

  /// The day of the month the item falls on, or `null` when it has none.
  final int? day;

  @override
  List<Object?> get props => [name, amount, kind, part, day];
}

/// A fixed item of a month, as the server holds it.
final class FixedItem extends Equatable {
  const new({
    required this.id,
    required this.name,
    required this.amount,
    required this.kind,
    required this.part,
    this.day,
    this.version = 1,
  });

  new fromDraft(this.id, FixedItemDraft draft, {this.version = 1})
    : name = draft.name,
      amount = draft.amount,
      kind = draft.kind,
      part = draft.part,
      day = draft.day;

  final String id;
  final String name;

  /// Always positive: [kind] says which way it goes.
  final Money amount;
  final FixedItemKind kind;
  final FixedItemPart part;

  /// The day of the month the item falls on, or `null` when it has none.
  final int? day;

  /// The server's version of the item, which a change or a delete sends back
  /// so an edit made on another device is never replaced unseen.
  final int version;

  /// The amount with its sign: positive for income, negative for an expense.
  Money get signedAmount => kind == FixedItemKind.income ? amount : -amount;

  /// What the item is made of, to edit it.
  FixedItemDraft get draft {
    return FixedItemDraft(
      name: name,
      amount: amount,
      kind: kind,
      part: part,
      day: day,
    );
  }

  @override
  List<Object?> get props => [id, name, amount, kind, part, day, version];
}
