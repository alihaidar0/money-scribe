import 'package:equatable/equatable.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';

/// What narrows the list of transactions: the words typed in the search, and
/// the choices of the Filters sheet.
final class TransactionFilter extends Equatable {
  const new({
    this.query = '',
    this.categoryIds = const {},
    this.accountIds = const {},
    this.from,
    this.to,
  });

  /// The most categories, and the most accounts, one filter takes.
  static const maxIds = 20;

  /// The shortest search the server takes.
  static const minSearchLength = 2;

  /// The longest search the server takes.
  static const maxSearchLength = 100;

  /// The words of the search. A transaction matches when its note contains
  /// them, whatever the case. The category and the account are narrowed with
  /// the Filters sheet, not by searching.
  final String query;

  /// The categories to show, or every category when empty.
  final Set<String> categoryIds;

  /// The accounts to show, or every account when empty.
  final Set<String> accountIds;

  /// The first and the last day to show, or no limit when `null`.
  final DateTime? from;
  final DateTime? to;

  /// Whether the search has words.
  bool get hasQuery => query.trim().isNotEmpty;

  /// The words to send to the server, or `null` while there are fewer than the
  /// server takes (one letter is not a search). A longer text is cut.
  String? get searchTerm {
    final words = query.trim();
    if (words.length < minSearchLength) return null;
    return words.length <= maxSearchLength
        ? words
        : words.substring(0, maxSearchLength);
  }

  /// Whether the server is asked to search the notes. The totals of a day
  /// would mislead then (they are of every transaction of the day, not of the
  /// ones found), so they are not shown.
  bool get isSearching => searchTerm != null;

  /// Whether the Filters sheet narrows the list by category, account or day.
  bool get hasSheetFilters {
    return categoryIds.isNotEmpty ||
        accountIds.isNotEmpty ||
        from != null ||
        to != null;
  }

  /// Whether anything narrows the list.
  bool get isActive => hasQuery || hasSheetFilters;

  /// The same filter with its search words changed.
  TransactionFilter withQuery(String query) {
    return TransactionFilter(
      query: query,
      categoryIds: categoryIds,
      accountIds: accountIds,
      from: from,
      to: to,
    );
  }

  /// The same search with the choices of the Filters sheet taken from [other].
  TransactionFilter withSheetFiltersOf(TransactionFilter other) {
    return TransactionFilter(
      query: query,
      categoryIds: other.categoryIds,
      accountIds: other.accountIds,
      from: other.from,
      to: other.to,
    );
  }

  /// How many choices of the Filters sheet narrow the list: each category,
  /// each account, and the days (as one).
  int get sheetFilterCount {
    return categoryIds.length +
        accountIds.length +
        (from != null || to != null ? 1 : 0);
  }

  /// The same filter without the category [id].
  TransactionFilter withoutCategory(String id) {
    return TransactionFilter(
      query: query,
      categoryIds: {...categoryIds}..remove(id),
      accountIds: accountIds,
      from: from,
      to: to,
    );
  }

  /// The same filter without the account [id].
  TransactionFilter withoutAccount(String id) {
    return TransactionFilter(
      query: query,
      categoryIds: categoryIds,
      accountIds: {...accountIds}..remove(id),
      from: from,
      to: to,
    );
  }

  /// The same filter without the days.
  TransactionFilter withoutDates() {
    return TransactionFilter(
      query: query,
      categoryIds: categoryIds,
      accountIds: accountIds,
    );
  }

  /// Whether [transaction] passes the filter, as the server decides it: the
  /// categories, the accounts, the days (both included) and the words in the
  /// note.
  bool matches(Transaction transaction) {
    if (categoryIds.isNotEmpty &&
        !categoryIds.contains(transaction.categoryId)) {
      return false;
    }
    if (accountIds.isNotEmpty && !accountIds.contains(transaction.accountId)) {
      return false;
    }
    final date = transaction.date;
    if (from != null && date.isBefore(_day(from!))) return false;
    if (to != null && date.isAfter(_day(to!))) return false;

    final words = searchTerm?.toLowerCase();
    if (words == null) return true;
    return transaction.note.toLowerCase().contains(words);
  }

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  List<Object?> get props => [query, categoryIds, accountIds, from, to];
}
