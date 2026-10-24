import 'package:money_scribe/core/errors/data_exception.dart';

/// One page of a list that the server cuts into pages: its [items], and where
/// the next page is ([next], or `null` on the last one).
final class Paged<T> {
  const new({required this.items, this.next});

  final List<T> items;

  /// What the server gave to ask for the next page, exactly as it came.
  final String? next;
}

/// Reads every page of a list, one after the other, and joins them.
/// [fetch] gets what the previous page gave as `next` (`null` for the first
/// page).
///
/// A server that keeps giving pages, or gives the same page address again,
/// is a failure and not an endless wait: [maxPages] stops it.
Future<List<T>> readAllPages<T>(
  Future<Paged<T>> Function(String? next) fetch, {
  int maxPages = defaultMaxPages,
}) async {
  final items = <T>[];
  final seen = <String>{};
  String? next;
  for (var page = 0; page < maxPages; page++) {
    final answer = await fetch(next);
    items.addAll(answer.items);
    next = answer.next;
    if (next == null) return items;
    if (!seen.add(next)) throw const ServerException();
  }
  throw const ServerException();
}

/// Enough pages for any list of the app: 100 items a page, 50 pages.
const defaultMaxPages = 50;
