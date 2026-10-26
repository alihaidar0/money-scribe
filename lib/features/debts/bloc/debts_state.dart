part of 'debts_bloc.dart';

/// Which debts the list shows.
enum DebtsFilter { all, lent, borrowed }

enum DebtsStatus {
  /// The debts are being loaded.
  loading,

  /// The debts are shown, or there are none.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

/// How deleting a debt from the detail pane went.
enum DebtsDeleteStatus {
  /// Nothing is being deleted.
  idle,

  /// The server is deleting the debt.
  deleting,

  /// The server did not delete it.
  failed,

  /// The debt had been changed on another device, so it was not deleted; the
  /// list is read again.
  stale,
}

final class DebtsState extends Equatable {
  const new({
    required this.today,
    this.status = DebtsStatus.loading,
    this.debts = const [],
    this.filter = DebtsFilter.all,
    this.selectedId,
    this.deleteStatus = DebtsDeleteStatus.idle,
    this.deletingId,
    this.defaultCurrency,
  });

  final DebtsStatus status;

  /// Every debt, in the order they were added, in every currency.
  final List<Debt> debts;
  final DebtsFilter filter;

  /// The debt the person chose to see in the detail pane, if any.
  final String? selectedId;

  final DebtsDeleteStatus deleteStatus;

  /// The debt of the last delete, so a failed one can be repeated.
  final String? deletingId;

  /// The day of today, which decides which debts are overdue.
  final DateTime today;

  /// The default currency of the account, which the totals are in, once it
  /// is known.
  final Currency? defaultCurrency;

  /// The currency of the totals.
  Currency get totalsCurrency =>
      defaultCurrency ?? debts.firstOrNull?.amount.currency ?? Currency.rub;

  /// Whether some debt is in another currency than the totals', and so is not
  /// in them: amounts of two currencies are never added.
  bool get hasOtherCurrencies {
    return debts.any((debt) => debt.amount.currency != totalsCurrency);
  }

  /// The debts of the chosen kind, those still to be repaid first.
  List<Debt> get shown {
    final matching = [
      for (final debt in debts)
        if (switch (filter) {
          DebtsFilter.all => true,
          DebtsFilter.lent => debt.direction == DebtDirection.lent,
          DebtsFilter.borrowed => debt.direction == DebtDirection.borrowed,
        })
          debt,
    ];
    return [
      ...matching.where((debt) => !debt.isSettled),
      ...matching.where((debt) => debt.isSettled),
    ];
  }

  /// The debt the detail pane shows: the chosen one while it is in the list,
  /// otherwise the first of the list.
  Debt? get selected {
    final list = shown;
    return list.where((debt) => debt.id == selectedId).firstOrNull ??
        list.firstOrNull;
  }

  /// What is still to be repaid to the person: the sum of what is left of the
  /// debts lent.
  Money get owedToYou => _remaining(DebtDirection.lent);

  /// What the person still has to repay: the sum of what is left of the debts
  /// borrowed.
  Money get youOwe => _remaining(DebtDirection.borrowed);

  Money _remaining(DebtDirection direction) {
    return debts
        .where(
          (debt) =>
              debt.direction == direction &&
              debt.amount.currency == totalsCurrency,
        )
        .fold<Money>(
          Money.zero(totalsCurrency),
          (sum, debt) => sum + debt.remaining,
        );
  }

  DebtsState copyWith({
    DebtsStatus? status,
    List<Debt>? debts,
    DebtsFilter? filter,
    DateTime? today,
    String? selectedId,
    DebtsDeleteStatus? deleteStatus,
    String? deletingId,
    Currency? defaultCurrency,
  }) {
    return DebtsState(
      status: status ?? this.status,
      debts: debts ?? this.debts,
      filter: filter ?? this.filter,
      today: today ?? this.today,
      selectedId: selectedId ?? this.selectedId,
      deleteStatus: deleteStatus ?? this.deleteStatus,
      deletingId: deletingId ?? this.deletingId,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    );
  }

  @override
  List<Object?> get props => [
    status,
    debts,
    filter,
    today,
    selectedId,
    deleteStatus,
    deletingId,
    defaultCurrency,
  ];
}
