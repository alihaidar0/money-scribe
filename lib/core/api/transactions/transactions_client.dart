// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/kind.dart';
import '../models/paginated_transaction_list.dart';
import '../models/patched_transaction_update_request.dart';
import '../models/transaction.dart';
import '../models/transaction_create_request.dart';

part 'transactions_client.g.dart';

@RestApi()
abstract class TransactionsClient {
  factory TransactionsClient(Dio dio, {String? baseUrl}) = _TransactionsClient;

  /// The person's transactions.
  ///
  /// Newest day first, then the entry added last first (`-date`, `-created_at`, `-id`). Cursor pagination (`limit` 50 by default, 100 at most; follow `next`). The filters narrow the list; the same ones (except `search`) narrow the day totals. `search` is a case-insensitive substring of the note, 2 to 100 characters. An id that matches nothing, or no match at all, is `200` with an empty `results`.
  ///
  /// [accountId] - Repeat to match any of up to 20 accounts. An id that matches nothing is not an error.
  ///
  /// [categoryId] - Repeat to match any of up to 20 categories. An id that matches nothing is not an error.
  ///
  /// [cursor] - An opaque position taken from `next` or `previous`; never built by the client.
  ///
  /// [dateFrom] - The first day, inclusive (`YYYY-MM-DD`).
  ///
  /// [dateTo] - The last day, inclusive (`YYYY-MM-DD`).
  ///
  /// [kind] - * `expense` - Expense.
  /// * `income` - Income.
  ///
  /// [limit] - How many results a page holds: 50 by default, at most 100.
  ///
  /// [search] - A case-insensitive substring of the note, 2 to 100 characters; `%` and `_` are ordinary characters. A list asked with `search` counts in the search rate group.
  @GET('/api/v1/transactions/')
  Future<PaginatedTransactionList> transactionList({
    @Query('account_id') List<String>? accountId,
    @Query('category_id') List<String>? categoryId,
    @Query('cursor') String? cursor,
    @Query('date_from') DateTime? dateFrom,
    @Query('date_to') DateTime? dateTo,
    @Query('kind') Kind? kind,
    @Query('limit') int? limit,
    @Query('search') String? search,
  });

  /// Add a transaction.
  ///
  /// Needs an `Idempotency-Key`. `amount` is a decimal string with exactly the digits of `currency` and greater than 0; the `kind` carries the sign. The `date` is a calendar day from 2000-01-01 to 2099-12-31 (`400` `date_out_of_range`). The category must be a built-in one or the person's own and must allow the `kind` (`400` `category_not_allowed` on `category_id`); an unknown id, or one that belongs to someone else, is `400` `does_not_exist` on its field, with the same answer for both. A person has at most 100 000 transactions (`409` `transaction_limit_reached`).
  ///
  /// [idempotencyKey] - A random id, once per user action, as a quoted string of 16 to 64 letters, digits, hyphens or underscores (a UUID fits): `"8e03978e-40d5-43e8-bc93-6894a57f9324"`. Repeat the same request with the same key after a lost answer and nothing is created twice; the answer is replayed with `Idempotent-Replayed: true`. The key is honoured for 24 hours. Without it: `400` `idempotency_key_required` (`attr` `idempotency_key`).
  @POST('/api/v1/transactions/')
  Future<Transaction> transactionCreate({
    @Header('Idempotency-Key') required String idempotencyKey,
    @Body() required TransactionCreateRequest body,
  });

  /// Read a transaction.
  ///
  /// The transaction, or `404` when it is not the person's. Answers the `ETag` of its `version`.
  @GET('/api/v1/transactions/{id}/')
  Future<Transaction> transactionRead({@Path('id') required String id});

  /// Change a transaction.
  ///
  /// Changes any of `kind`, `amount`, `date`, `category_id`, `account_id`, `note`; the rules are those of the create, and a change of the kind or the category checks the category again. The `currency` cannot be changed: sending it, even the stored one, is `400` `read_only`, like any other field that cannot be written. Send `If-Match` with the `version`: a stale one (a category delete that moved this transaction counts) is `412` and changes nothing.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  @PATCH('/api/v1/transactions/{id}/')
  Future<Transaction> transactionUpdate({
    @Path('id') required String id,
    @Header('If-Match') String? ifMatch,
    @Body() PatchedTransactionUpdateRequest? body,
  });

  /// Delete a transaction.
  ///
  /// Deletes the transaction for good (`204`); `If-Match` is checked as for a change. A repeated delete is `404`: treat it as done.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  @DELETE('/api/v1/transactions/{id}/')
  Future<void> transactionDelete({
    @Path('id') required String id,
    @Header('If-Match') String? ifMatch,
  });
}
