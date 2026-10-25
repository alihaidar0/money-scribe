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
    this.twoPayments = false,
    this.currency = Currency.rub,
    this.part = FixedItemPart.first,
    this.failedAction,
    this.staleAction,
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

  /// Whether the month is paid in two payments, so its items have parts.
  final bool twoPayments;

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
    );
  }

  FixedItemsState copyWith({
    FixedItemsStatus? status,
    bool? monthSaved,
    List<FixedItem>? items,
    SalaryResult? salary,
    bool clearSalary = false,
    bool? twoPayments,
    Currency? currency,
    FixedItemPart? part,
    FixedItemsEvent? failedAction,
    bool clearFailedAction = false,
    FixedItemsEvent? staleAction,
    bool clearStaleAction = false,
  }) {
    return FixedItemsState(
      month: month,
      status: status ?? this.status,
      monthSaved: monthSaved ?? this.monthSaved,
      items: items ?? this.items,
      salary: clearSalary ? null : salary ?? this.salary,
      twoPayments: twoPayments ?? this.twoPayments,
      currency: currency ?? this.currency,
      part: part ?? this.part,
      failedAction: clearFailedAction
          ? null
          : failedAction ?? this.failedAction,
      staleAction: clearStaleAction ? null : staleAction ?? this.staleAction,
    );
  }

  @override
  List<Object?> get props => [
    status,
    month,
    monthSaved,
    items,
    salary,
    twoPayments,
    currency,
    part,
    failedAction,
    staleAction,
  ];
}
