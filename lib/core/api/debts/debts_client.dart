// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/debt.dart';
import '../models/debt_create_request.dart';
import '../models/direction.dart';
import '../models/paginated_debt_list.dart';
import '../models/patched_debt_update_request.dart';
import '../models/patched_repayment_input_request.dart';
import '../models/repayment_input_request.dart';
import '../models/status2.dart';

part 'debts_client.g.dart';

@RestApi()
abstract class DebtsClient {
  factory DebtsClient(Dio dio, {String? baseUrl}) = _DebtsClient;

  /// The person's debts.
  ///
  /// Newest first (`-created_at`, `-id`), each with its `repayments` inline and its derived `repaid`, `remaining` and `status`. Cursor pagination (`limit` 50 by default, 100 at most; follow `next`). `status` repeats and matches any of the values; `search` is a case-insensitive substring of the person, 2 to 50 characters. A filter that matches nothing is `200` with an empty `results`.
  ///
  /// [cursor] - An opaque position taken from `next` or `previous`; never built by the client.
  ///
  /// [direction] - * `lent` - Lent.
  /// * `borrowed` - Borrowed.
  ///
  /// [limit] - How many results a page holds: 50 by default, at most 100.
  ///
  /// [search] - A case-insensitive substring of the person, 2 to 50 characters; `%` and `_` are ordinary characters. A list asked with `search` counts in the search rate group.
  ///
  /// [status] - Repeat to match any of the statuses.
  ///
  /// [today] - A calendar day (`YYYY-MM-DD`) that replaces the person's current day when the `status` is worked out. The app leaves it out.
  @GET('/api/v1/debts/')
  Future<PaginatedDebtList> debtList({
    @Query('cursor') String? cursor,
    @Query('direction') Direction? direction,
    @Query('limit') int? limit,
    @Query('search') String? search,
    @Query('status') List<Status2>? status,
    @Query('today') DateTime? today,
  });

  /// Add a debt.
  ///
  /// Needs an `Idempotency-Key`. `amount` is a decimal string with exactly the digits of `currency` and greater than 0. The dates are calendar days from 2000-01-01 to 2099-12-31 (`400` `date_out_of_range`) and the `due_date`, if any, is not before the `start_date` (`400` `due_before_start`). The debt starts with no repayments. A person has at most 500 debts (`409` `debt_limit_reached`).
  ///
  /// [idempotencyKey] - A random id, once per user action, as a quoted string of 16 to 64 letters, digits, hyphens or underscores (a UUID fits): `"8e03978e-40d5-43e8-bc93-6894a57f9324"`. Repeat the same request with the same key after a lost answer and nothing is created twice; the answer is replayed with `Idempotent-Replayed: true`. The key is honoured for 24 hours. Without it: `400` `idempotency_key_required` (`attr` `idempotency_key`).
  @POST('/api/v1/debts/')
  Future<Debt> debtCreate({
    @Header('Idempotency-Key') required String idempotencyKey,
    @Body() required DebtCreateRequest body,
  });

  /// Read a debt.
  ///
  /// The debt with its repayments, or `404` when it is not the person's. Answers the `ETag` of its `version`.
  ///
  /// [today] - A calendar day (`YYYY-MM-DD`) that replaces the person's current day when the `status` is worked out. The app leaves it out.
  @GET('/api/v1/debts/{id}/')
  Future<Debt> debtRead({
    @Path('id') required String id,
    @Query('today') DateTime? today,
  });

  /// Change a debt.
  ///
  /// Changes any of `direction`, `person`, `amount`, `start_date`, `due_date`, `note`; fields not sent keep their value. Flipping the `direction` (a debt added as `lent` instead of `borrowed`, or the reverse) keeps the repayments, the amount and the dates, and the status does not depend on it. `{"due_date": null}` clears the due date and `"note": ""` the note; `note: null` is `400`. The `currency` cannot be changed: sending it, even the stored value, is `400` `read_only`, like every derived field and any unknown field. The `amount` cannot go below what was repaid (`400` `amount_below_repaid`) and the `start_date` cannot go past a repayment (`400` `start_after_repayment`). Send `If-Match` with the `version`: a stale one is `412` and changes nothing.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  @PATCH('/api/v1/debts/{id}/')
  Future<Debt> debtUpdate({
    @Path('id') required String id,
    @Header('If-Match') String? ifMatch,
    @Body() PatchedDebtUpdateRequest? body,
  });

  /// Delete a debt.
  ///
  /// Deletes the debt and its repayments in one transaction (`204`); `If-Match` is checked as for a change. A repeated delete is `404`: treat it as done.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  @DELETE('/api/v1/debts/{id}/')
  Future<void> debtDelete({
    @Path('id') required String id,
    @Header('If-Match') String? ifMatch,
  });

  /// Add a repayment.
  ///
  /// Needs an `Idempotency-Key`. Answers `201` with the whole debt, so the app has the new `repaid`, `remaining` and `status` at once; its `ETag` is the debt's `version`, which a repayment does not change. The repayment is in the debt's currency: a `currency` in the request is `400` `read_only`. An `amount` above what remains is `400` `exceeds_remaining` on `amount`, and the error also carries `remaining`. A `date` before the debt's `start_date` is `400` `repayment_before_start`. A debt has at most 200 repayments (`409` `repayment_limit_reached`). The debt is locked while the repayment is added, so two devices cannot overpay it together.
  ///
  /// [idempotencyKey] - A random id, once per user action, as a quoted string of 16 to 64 letters, digits, hyphens or underscores (a UUID fits): `"8e03978e-40d5-43e8-bc93-6894a57f9324"`. Repeat the same request with the same key after a lost answer and nothing is created twice; the answer is replayed with `Idempotent-Replayed: true`. The key is honoured for 24 hours. Without it: `400` `idempotency_key_required` (`attr` `idempotency_key`).
  @POST('/api/v1/debts/{id}/repayments/')
  Future<Debt> debtRepaymentCreate({
    @Header('Idempotency-Key') required String idempotencyKey,
    @Path('id') required String id,
    @Body() required RepaymentInputRequest body,
  });

  /// Change a repayment.
  ///
  /// Changes `amount` and `date`; the rules are those of the create, and the repayment's own previous amount does not count towards what remains. Answers `200` with the whole debt and the debt's `ETag`. Send `If-Match` with the **repayment's** `version` (`repayments[].version`): a stale one is `412` and changes nothing. A repayment of another debt is `404`.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  ///
  /// [repaymentId] - The id of a repayment of this debt; another debt's repayment is `404`.
  @PATCH('/api/v1/debts/{id}/repayments/{repayment_id}/')
  Future<Debt> debtRepaymentUpdate({
    @Path('id') required String id,
    @Path('repayment_id') required String repaymentId,
    @Header('If-Match') String? ifMatch,
    @Body() PatchedRepaymentInputRequest? body,
  });

  /// Delete a repayment.
  ///
  /// Deletes the repayment and answers `200` with the whole debt; `If-Match` is the repayment's `version`, checked as for a change. A repeated delete is `404`: treat it as done.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  ///
  /// [repaymentId] - The id of a repayment of this debt; another debt's repayment is `404`.
  @DELETE('/api/v1/debts/{id}/repayments/{repayment_id}/')
  Future<Debt> debtRepaymentDelete({
    @Path('id') required String id,
    @Path('repayment_id') required String repaymentId,
    @Header('If-Match') String? ifMatch,
  });
}
