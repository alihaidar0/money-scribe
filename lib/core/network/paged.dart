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

/// The cursor inside the address the server gave for the next page, which is
/// sent back as it came and never built by the app.
///
/// Only an address on the API's own origin ([baseUrl]: scheme, host and port)
/// is followed, so a page can never send the app, and the token it carries,
/// to another server. An address elsewhere, or without a cursor, is a
/// failure.
String? cursorOfNextPage(String? next, {required String baseUrl}) {
  if (next == null) return null;
  final link = Uri.tryParse(next);
  final base = Uri.tryParse(baseUrl);
  if (link == null ||
      base == null ||
      !link.hasScheme ||
      link.scheme != base.scheme ||
      link.host != base.host ||
      link.port != base.port) {
    throw const ServerException();
  }
  final cursor = link.queryParameters['cursor'];
  if (cursor == null || cursor.isEmpty) throw const ServerException();
  return cursor;
}
