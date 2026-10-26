part of 'transactions_bloc.dart';

enum TransactionsStatus {
  /// The screen is being loaded for the first time.
  loading,

  /// The screen is shown: the search, the filters and the results.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

/// How the results under the search and the filters are doing, once the screen
/// is shown. They load again whenever the search, a filter or the part
/// changes, and the search field must stay where it is meanwhile.
enum TransactionsResultsStatus {
  /// The first page of the results is being loaded.
  loading,

  /// The results are shown, or there are none.
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

  /// The transaction was changed on another device first: the list was loaded
  /// again and nothing was deleted.
  stale,
}

final class TransactionsState extends Equatable {
  const new({
    this.status = TransactionsStatus.loading,
    this.resultsStatus = TransactionsResultsStatus.loading,
    this.transactions = const [],
    this.nextCursor,
    this.dayTotals = const {},
    this.nextDayTotalsCursor,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.hasTransactions = true,
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
  final TransactionsResultsStatus resultsStatus;

  /// The transactions that pass the search and the filters, as far as they are
  /// loaded: the newest first, a page at a time.
  final List<Transaction> transactions;

  /// What to ask for the next page of [transactions], or `null` when they are
  /// all loaded.
  final String? nextCursor;

  /// What each loaded day came to, which the server counts, by day. Empty
  /// while a search is on: the total of a day would count transactions the
  /// search left out.
  final Map<DateTime, List<Money>> dayTotals;

  /// What to ask for the next page of [dayTotals], or `null` when they are
  /// all loaded.
  final String? nextDayTotalsCursor;

  /// Whether the next page is being loaded.
  final bool loadingMore;

  /// Whether the last try to load the next page failed, so the end of the list
  /// can offer to try again.
  final bool loadMoreFailed;

  /// Whether the account has any transaction at all, to tell "nothing yet"
  /// from "nothing found". It is known after a load that nothing narrowed.
  final bool hasTransactions;

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

  /// Whether the search, a filter or a part narrows the list.
  bool get isNarrowed => filter.isActive || effectiveScope != PeriodScope.month;

  /// Whether the server is asked for only part of the days (a part of the
  /// month is chosen): the pages hold days that are not shown, so a page can
  /// add nothing to the list.
  bool get filtersByPart => effectiveScope != PeriodScope.month;

  /// The loaded transactions that are in the part shown. The server does the
  /// search and the other filters; the part is a half of every month, which
  /// it does not know, so it is cut here.
  List<Transaction> get visible {
    if (effectiveScope == PeriodScope.month) return transactions;
    return [
      for (final transaction in transactions)
        if (PeriodScope.partOfDay(transaction.date.day) == effectiveScope)
          transaction,
    ];
  }

  /// What the days came to, or `null` while a search is on.
  Map<DateTime, List<Money>>? get shownDayTotals {
    return filter.isSearching ? null : dayTotals;
  }

  /// The transaction the detail pane shows: the chosen one while it is in the
  /// list, otherwise the newest.
  Transaction? get selected {
    final list = visible;
    final chosen = list.where((item) => item.id == selectedId).firstOrNull;
    if (chosen != null || list.isEmpty) return chosen;
    return list.first;
  }

  TransactionsState copyWith({
    TransactionsStatus? status,
    TransactionsResultsStatus? resultsStatus,
    List<Transaction>? transactions,
    String? nextCursor,
    Map<DateTime, List<Money>>? dayTotals,
    String? nextDayTotalsCursor,
    bool clearNextCursor = false,
    bool clearNextDayTotalsCursor = false,
    bool? loadingMore,
    bool? loadMoreFailed,
    bool? hasTransactions,
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
      resultsStatus: resultsStatus ?? this.resultsStatus,
      transactions: transactions ?? this.transactions,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      dayTotals: dayTotals ?? this.dayTotals,
      nextDayTotalsCursor: clearNextDayTotalsCursor
          ? null
          : nextDayTotalsCursor ?? this.nextDayTotalsCursor,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      hasTransactions: hasTransactions ?? this.hasTransactions,
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
    resultsStatus,
    transactions,
    nextCursor,
    dayTotals,
    nextDayTotalsCursor,
    loadingMore,
    loadMoreFailed,
    hasTransactions,
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
