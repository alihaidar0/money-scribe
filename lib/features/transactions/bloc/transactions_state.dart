part of 'transactions_bloc.dart';

enum TransactionsStatus {
  /// The transactions are being loaded.
  loading,

  /// The transactions are shown, or there are none.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

/// How deleting a transaction from the detail pane went.
enum TransactionsDeleteStatus {
  /// Nothing is being deleted.
  idle,

  /// The server is deleting the transaction.
  deleting,

  /// The server did not delete it.
  failed,
}

final class TransactionsState extends Equatable {
  const new({
    this.status = TransactionsStatus.loading,
    this.transactions = const [],
    this.accounts = const [],
    this.categories = const [],
    this.twoPayments = false,
    this.filter = const TransactionFilter(),
    this.scope = PeriodScope.month,
    this.selectedId,
    this.deleteStatus = TransactionsDeleteStatus.idle,
    this.deletingId,
  });

  final TransactionsStatus status;

  /// Every transaction, in the order they were added.
  final List<Transaction> transactions;
  final List<Account> accounts;
  final List<TransactionCategory> categories;

  /// Whether the salary is paid in two payments, so the list is split by part
  /// of the month.
  final bool twoPayments;

  final TransactionFilter filter;

  /// The part of the month shown; the whole month for one payment.
  final PeriodScope scope;

  /// The transaction the person chose to see in the detail pane, if any.
  final String? selectedId;

  final TransactionsDeleteStatus deleteStatus;

  /// The transaction of the last delete, so a failed one can be repeated.
  final String? deletingId;

  /// The scope that is shown: a part only for two payments.
  PeriodScope get effectiveScope => twoPayments ? scope : PeriodScope.month;

  /// Whether the account has any transaction at all.
  bool get hasTransactions => transactions.isNotEmpty;

  /// Whether the search, a filter or a part narrows the list.
  bool get isNarrowed => filter.isActive || effectiveScope != PeriodScope.month;

  /// The transactions that pass the search, the filters and the part.
  List<Transaction> get visible {
    final categoryNames = {
      for (final category in categories) category.id: category.name,
    };
    final accountNames = {
      for (final account in accounts) account.id: account.name,
    };

    return [
      for (final transaction in transactions)
        if (filter.matches(
              transaction,
              categoryName: categoryNames[transaction.categoryId] ?? '',
              accountName: accountNames[transaction.accountId] ?? '',
            ) &&
            (effectiveScope == PeriodScope.month ||
                PeriodScope.partOfDay(transaction.date.day) == effectiveScope))
          transaction,
    ];
  }

  /// The transaction the detail pane shows: the chosen one while it is in the
  /// list, otherwise the newest.
  Transaction? get selected {
    final list = visible;
    final chosen = list.where((item) => item.id == selectedId).firstOrNull;
    if (chosen != null || list.isEmpty) return chosen;
    return list.reduce((a, b) => b.date.isAfter(a.date) ? b : a);
  }

  TransactionsState copyWith({
    TransactionsStatus? status,
    List<Transaction>? transactions,
    List<Account>? accounts,
    List<TransactionCategory>? categories,
    bool? twoPayments,
    TransactionFilter? filter,
    PeriodScope? scope,
    String? selectedId,
    TransactionsDeleteStatus? deleteStatus,
    String? deletingId,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      accounts: accounts ?? this.accounts,
      categories: categories ?? this.categories,
      twoPayments: twoPayments ?? this.twoPayments,
      filter: filter ?? this.filter,
      scope: scope ?? this.scope,
      selectedId: selectedId ?? this.selectedId,
      deleteStatus: deleteStatus ?? this.deleteStatus,
      deletingId: deletingId ?? this.deletingId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    transactions,
    accounts,
    categories,
    twoPayments,
    filter,
    scope,
    selectedId,
    deleteStatus,
    deletingId,
  ];
}
