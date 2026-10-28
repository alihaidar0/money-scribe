// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/account.dart';
import '../models/account_input_request.dart';
import '../models/paginated_account_list.dart';
import '../models/patched_account_input_request.dart';

part 'accounts_client.g.dart';

@RestApi()
abstract class AccountsClient {
  factory AccountsClient(Dio dio, {String? baseUrl}) = _AccountsClient;

  /// The person's accounts.
  ///
  /// The accounts in the order they were made (the default "Card" before "Cash"). Cursor pagination (`limit`, `cursor`; follow `next`): ask `limit=100` to get the whole list in one call. A person who deleted every account gets `200` with an empty `results`.
  ///
  /// [cursor] - An opaque position taken from `next` or `previous`; never built by the client.
  ///
  /// [limit] - How many results a page holds: 50 by default, at most 100.
  @GET('/api/v1/accounts/')
  Future<PaginatedAccountList> accountList({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });

  /// Add an account.
  ///
  /// Needs an `Idempotency-Key`. A person has at most 20 accounts (`409` `account_limit_reached`). The name is unique per person in any case (`400` `name_taken`, `attr` `name`). Every account gets "Card" and "Cash" when its email is verified, in the language of the account; they are ordinary accounts.
  ///
  /// [idempotencyKey] - A random id, once per user action, as a quoted string of 16 to 64 letters, digits, hyphens or underscores (a UUID fits): `"8e03978e-40d5-43e8-bc93-6894a57f9324"`. Repeat the same request with the same key after a lost answer and nothing is created twice; the answer is replayed with `Idempotent-Replayed: true`. The key is honoured for 24 hours. Without it: `400` `idempotency_key_required` (`attr` `idempotency_key`).
  @POST('/api/v1/accounts/')
  Future<Account> accountCreate({
    @Header('Idempotency-Key') required String idempotencyKey,
    @Body() required AccountInputRequest body,
  });

  /// Read an account.
  ///
  /// The account, or `404` when it is not the person's. Answers the `ETag` of its `version`.
  @GET('/api/v1/accounts/{id}/')
  Future<Account> accountRead({@Path('id') required String id});

  /// Change an account.
  ///
  /// Changes `name` and `kind`. Send `If-Match` with the `version`: a stale one is `412` and changes nothing. A name that is taken is `400` `name_taken`. Any other field is `400` `read_only`.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  @PATCH('/api/v1/accounts/{id}/')
  Future<Account> accountUpdate({
    @Path('id') required String id,
    @Header('If-Match') String? ifMatch,
    @Body() PatchedAccountInputRequest? body,
  });

  /// Delete an account.
  ///
  /// Deletes the account (`204`); `If-Match` is checked as for a change. An account that has transactions is refused and nothing changes: `409` `account_has_transactions`. A repeated delete is `404`: treat it as done.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  @DELETE('/api/v1/accounts/{id}/')
  Future<void> accountDelete({
    @Path('id') required String id,
    @Header('If-Match') String? ifMatch,
  });
}
