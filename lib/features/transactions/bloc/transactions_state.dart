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

final class TransactionsState extends Equatable {
  const new({
    this.status = TransactionsStatus.loading,
    this.transactions = const [],
    this.accounts = const [],
    this.categories = const [],
    this.twoPayments = false,
    this.filter = const TransactionFilter(),
    this.scope = PeriodScope.month,
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

  TransactionsState copyWith({
    TransactionsStatus? status,
    List<Transaction>? transactions,
    List<Account>? accounts,
    List<TransactionCategory>? categories,
    bool? twoPayments,
    TransactionFilter? filter,
    PeriodScope? scope,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      accounts: accounts ?? this.accounts,
      categories: categories ?? this.categories,
      twoPayments: twoPayments ?? this.twoPayments,
      filter: filter ?? this.filter,
      scope: scope ?? this.scope,
    );
  }

  @override
  List<Object> get props => [
    status,
    transactions,
    accounts,
    categories,
    twoPayments,
    filter,
    scope,
  ];
}
