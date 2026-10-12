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

final class DebtsState extends Equatable {
  const new({
    required this.today,
    this.status = DebtsStatus.loading,
    this.debts = const [],
    this.filter = DebtsFilter.all,
  });

  final DebtsStatus status;

  /// Every debt, in the order they were added.
  final List<Debt> debts;
  final DebtsFilter filter;

  /// The day of today, which decides which debts are overdue.
  final DateTime today;

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

  /// What is still to be repaid to the person: the sum of what is left of the
  /// debts lent.
  Money get owedToYou => _remaining(DebtDirection.lent);

  /// What the person still has to repay: the sum of what is left of the debts
  /// borrowed.
  Money get youOwe => _remaining(DebtDirection.borrowed);

  Money _remaining(DebtDirection direction) {
    return debts
        .where((debt) => debt.direction == direction)
        .fold<Money>(
          Money.zero(
            debts.isEmpty ? Currency.rub : debts.first.amount.currency,
          ),
          (sum, debt) => sum + debt.remaining,
        );
  }

  DebtsState copyWith({
    DebtsStatus? status,
    List<Debt>? debts,
    DebtsFilter? filter,
    DateTime? today,
  }) {
    return DebtsState(
      status: status ?? this.status,
      debts: debts ?? this.debts,
      filter: filter ?? this.filter,
      today: today ?? this.today,
    );
  }

  @override
  List<Object> get props => [status, debts, filter, today];
}
