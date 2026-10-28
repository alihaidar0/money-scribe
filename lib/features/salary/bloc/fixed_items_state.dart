part of 'fixed_items_bloc.dart';

enum FixedItemsStatus {
  /// The fixed items are being loaded.
  loading,

  /// The fixed items are shown, or the month has none.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class FixedItemsState extends Equatable {
  const new({
    required this.month,
    this.status = FixedItemsStatus.loading,
    this.monthSaved = false,
    this.items = const [],
    this.salary,
    this.balances,
    this.twoPayments = false,
    this.firstPayDay = 20,
    this.secondPayDay = 5,
    this.currency = Currency.rub,
    this.part = FixedItemPart.first,
    this.failedAction,
    this.staleAction,
    this.copying = false,
    this.copyRefusal,
  });

  final FixedItemsStatus status;

  /// The month the fixed items belong to.
  final YearMonth month;

  /// Whether the month's salary is saved. Fixed items belong to a saved month,
  /// so a month that is not saved has none and cannot take any.
  final bool monthSaved;

  /// Every fixed item of the month, in the order they were added.
  final List<FixedItem> items;

  /// What the month's salary comes to, or `null` when none was saved.
  final SalaryResult? salary;

  /// The balances the server calculated for the items of the month, or `null`
  /// when it gave none or the items changed since: the summary then adds them
  /// up here until the server's arrive.
  final SalaryBalances? balances;

  /// Whether the month is paid in two payments, so its items have parts.
  final bool twoPayments;

  /// The days the two payments of the month are received on: the first in the
  /// month, the second in the next. They decide which part an item falls in.
  final int firstPayDay;
  final int secondPayDay;

  /// The currency of the month's salary, which the items are in.
  final Currency currency;

  /// The part shown, for a month paid in two payments.
  final FixedItemPart part;

  /// The last add, change or delete that the server did not accept, so the
  /// screen can offer to try it again. `null` once something else was done.
  final FixedItemsEvent? failedAction;

  /// The last add, change or delete that was not done because the item was
  /// changed on another device; the list was loaded again. `null` once
  /// something else was done.
  final FixedItemsEvent? staleAction;

  /// Whether the items of another month are being copied into this one.
  final bool copying;

  /// Why the last copy was refused, so the screen can say so. `null` once
  /// something else was done.
  final FixedItemsCopyRefusal? copyRefusal;

  /// The items on screen: all of them, or those of [part].
  List<FixedItem> get shownItems {
    return FixedItemsSummary.shown(items, twoPayments: twoPayments, part: part);
  }

  /// The balance of the pay after the fixed items.
  FixedItemsSummary get summary {
    return FixedItemsSummary.of(
      items: items,
      salary: salary,
      currency: currency,
      twoPayments: twoPayments,
      part: part,
      balances: balances,
    );
  }

  FixedItemsState copyWith({
    FixedItemsStatus? status,
    bool? monthSaved,
    List<FixedItem>? items,
    SalaryResult? salary,
    bool clearSalary = false,
    SalaryBalances? balances,
    bool clearBalances = false,
    bool? twoPayments,
    int? firstPayDay,
    int? secondPayDay,
    Currency? currency,
    FixedItemPart? part,
    FixedItemsEvent? failedAction,
    bool clearFailedAction = false,
    FixedItemsEvent? staleAction,
    bool clearStaleAction = false,
    bool? copying,
    FixedItemsCopyRefusal? copyRefusal,
    bool clearCopyRefusal = false,
  }) {
    return FixedItemsState(
      month: month,
      status: status ?? this.status,
      monthSaved: monthSaved ?? this.monthSaved,
      items: items ?? this.items,
      salary: clearSalary ? null : salary ?? this.salary,
      balances: clearBalances ? null : balances ?? this.balances,
      twoPayments: twoPayments ?? this.twoPayments,
      firstPayDay: firstPayDay ?? this.firstPayDay,
      secondPayDay: secondPayDay ?? this.secondPayDay,
      currency: currency ?? this.currency,
      part: part ?? this.part,
      failedAction: clearFailedAction
          ? null
          : failedAction ?? this.failedAction,
      staleAction: clearStaleAction ? null : staleAction ?? this.staleAction,
      copying: copying ?? this.copying,
      copyRefusal: clearCopyRefusal ? null : copyRefusal ?? this.copyRefusal,
    );
  }

  @override
  List<Object?> get props => [
    status,
    month,
    monthSaved,
    items,
    salary,
    balances,
    twoPayments,
    firstPayDay,
    secondPayDay,
    currency,
    part,
    failedAction,
    staleAction,
    copying,
    copyRefusal,
  ];
}
