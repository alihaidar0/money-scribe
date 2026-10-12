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

  /// The words of the search. A transaction matches when its category, its
  /// account or its note contains them, whatever the case.
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

  /// Whether [transaction] passes the filter. [categoryName] and
  /// [accountName] are what the search looks in besides the note.
  bool matches(
    Transaction transaction, {
    required String categoryName,
    required String accountName,
  }) {
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

    final words = query.trim().toLowerCase();
    if (words.isEmpty) return true;
    return categoryName.toLowerCase().contains(words) ||
        accountName.toLowerCase().contains(words) ||
        transaction.note.toLowerCase().contains(words);
  }

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  List<Object?> get props => [query, categoryIds, accountIds, from, to];
}
