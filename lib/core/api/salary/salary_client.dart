// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/copy_fixed_items_request.dart';
import '../models/defaults.dart';
import '../models/fixed_item.dart';
import '../models/fixed_item_input_request.dart';
import '../models/paginated_salary_month_list.dart';
import '../models/patched_fixed_item_input_request.dart';
import '../models/salary_month.dart';
import '../models/salary_month_input_request.dart';

part 'salary_client.g.dart';

@RestApi()
abstract class SalaryClient {
  factory SalaryClient(Dio dio, {String? baseUrl}) = _SalaryClient;

  /// Change a fixed item.
  ///
  /// Changes any of `name`, `amount`, `kind`, `part`; the `currency`, if sent, must be the month's. Send `If-Match` with the item's `version`: a stale one is `412` and changes nothing. Answers the item and its new `ETag`; the month's `version` does not change, but its `fixed_totals` and `balances` do.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  @PATCH('/api/v1/salary/fixed-items/{id}/')
  Future<FixedItem> salaryFixedItemUpdate({
    @Path('id') required String id,
    @Header('If-Match') String? ifMatch,
    @Body() PatchedFixedItemInputRequest? body,
  });

  /// Delete a fixed item.
  ///
  /// Deletes the item (`204`); `If-Match` is checked as for a change. A repeated delete is `404`: treat it as done.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  @DELETE('/api/v1/salary/fixed-items/{id}/')
  Future<void> salaryFixedItemDelete({
    @Path('id') required String id,
    @Header('If-Match') String? ifMatch,
  });

  /// The history of salary months.
  ///
  /// The user's saved months, newest first, each with its results, fixed items, totals and balances, so the app needs one call to show the history and to compare two months. Cursor pagination (`limit`, `cursor`; follow `next`). An empty history is `200` with an empty `results`.
  ///
  /// [cursor] - An opaque position taken from `next` or `previous`; never built by the client.
  ///
  /// [limit] - How many results a page holds: 50 by default, at most 100.
  @GET('/api/v1/salary/months/')
  Future<PaginatedSalaryMonthList> salaryMonthList({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });

  /// Read a salary month.
  ///
  /// The month, or `404` when it is not saved. Answers the `ETag` of its `version`.
  ///
  /// [month] - The month, `YYYY-MM`, from 2000-01 to 2099-12. Any other key is not a route (a plain `404`).
  @GET('/api/v1/salary/months/{month}/')
  Future<SalaryMonth> salaryMonthRead({@Path('month') required String month});

  /// Save a salary month.
  ///
  /// Creates the month (`201`) or replaces its inputs as a whole (`200`); the server calculates the results. The fixed items are never sent here and are never touched. Send `If-None-Match: *` when the form is for a month the app did not find, so a month created meanwhile on another device is not replaced (`412`), or `If-Match` with the `version` of the month it loaded. Errors: `400` on the field that is wrong (`invalid_amount` for an amount that does not fit the currency or a result above the largest amount, `invalid_choice` for a currency); `409` `month_has_fixed_items` for another currency while the month has fixed items; `412` `precondition_failed`.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  ///
  /// [ifNoneMatch] - Only `*` is accepted: the record must not exist yet. Send it when the form is for a record the app did not find, so one created meanwhile on another device is not replaced. If the record exists nothing changes and the answer is `412` `precondition_failed`. Without the header a request on an existing record replaces it.
  ///
  /// [month] - The month, `YYYY-MM`, from 2000-01 to 2099-12. Any other key is not a route (a plain `404`).
  @PUT('/api/v1/salary/months/{month}/')
  Future<SalaryMonth> salaryMonthPut({
    @Path('month') required String month,
    @Body() required SalaryMonthInputRequest body,
    @Header('If-Match') String? ifMatch,
    @Header('If-None-Match') String? ifNoneMatch,
  });

  /// Delete a salary month.
  ///
  /// Deletes the month and its fixed items (`204`). `404` when it is not saved, `412` for a stale `If-Match`.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  ///
  /// [month] - The month, `YYYY-MM`, from 2000-01 to 2099-12. Any other key is not a route (a plain `404`).
  @DELETE('/api/v1/salary/months/{month}/')
  Future<void> salaryMonthDelete({
    @Path('month') required String month,
    @Header('If-Match') String? ifMatch,
  });

  /// The inputs to pre-fill a month.
  ///
  /// The inputs of the form for a month, whether or not it is saved. Carried from the most recent saved month (never the month itself): `working_hours_in_month`, `tax_rate_basis_points`, and `base_salary` and `food_per_day` only when the currency is the same (else `null`). The pay schedule is that month's, then the app's own defaults (one payment, days 20 and 5; tax 1300). The currency and the pay schedule the person has set in the Settings come first (a value never set falls through to the month). `working_days_in_month` and `working_days_first_half` are `null` and `extra_hours_hundredths` is `0`.
  ///
  /// [month] - The month, `YYYY-MM`, from 2000-01 to 2099-12. Any other key is not a route (a plain `404`).
  @GET('/api/v1/salary/months/{month}/defaults/')
  Future<Defaults> salaryMonthDefaults({@Path('month') required String month});

  /// Add a fixed item to a month.
  ///
  /// Adds a fixed income or expense to a saved month (`404` when the month is not saved). Needs an `Idempotency-Key`. The item has no currency of its own; one that is sent must be the month's (`400` `currency_mismatch`). A month holds at most 100 items (`409` `fixed_item_limit_reached`). The month's `fixed_totals` and `balances` change, so the app reads the month again.
  ///
  /// [idempotencyKey] - A random id, once per user action, as a quoted string of 16 to 64 letters, digits, hyphens or underscores (a UUID fits): `"8e03978e-40d5-43e8-bc93-6894a57f9324"`. Repeat the same request with the same key after a lost answer and nothing is created twice; the answer is replayed with `Idempotent-Replayed: true`. The key is honoured for 24 hours. Without it: `400` `idempotency_key_required` (`attr` `idempotency_key`).
  ///
  /// [month] - The month, `YYYY-MM`, from 2000-01 to 2099-12. Any other key is not a route (a plain `404`).
  @POST('/api/v1/salary/months/{month}/fixed-items/')
  Future<FixedItem> salaryFixedItemCreate({
    @Header('Idempotency-Key') required String idempotencyKey,
    @Path('month') required String month,
    @Body() required FixedItemInputRequest body,
  });

  /// Copy the fixed items of another month.
  ///
  /// Adds the fixed items of another saved month to this one (`name`, `amount`, `kind`, `part`, with new ids) and answers this month. Needs an `Idempotency-Key`. `from` is the month to copy from; without it, the most recent saved month before this one. Errors: `404` for a month or a source that is not saved (also when there is no earlier month); `400` on `from` when it is the month itself or has another currency (`currency_mismatch`); `409` `fixed_item_limit_reached` with nothing copied when the total would pass 100. A source with no items copies nothing and is not an error.
  ///
  /// [idempotencyKey] - A random id, once per user action, as a quoted string of 16 to 64 letters, digits, hyphens or underscores (a UUID fits): `"8e03978e-40d5-43e8-bc93-6894a57f9324"`. Repeat the same request with the same key after a lost answer and nothing is created twice; the answer is replayed with `Idempotent-Replayed: true`. The key is honoured for 24 hours. Without it: `400` `idempotency_key_required` (`attr` `idempotency_key`).
  ///
  /// [month] - The month, `YYYY-MM`, from 2000-01 to 2099-12. Any other key is not a route (a plain `404`).
  @POST('/api/v1/salary/months/{month}/fixed-items/copy/')
  Future<SalaryMonth> salaryFixedItemsCopy({
    @Header('Idempotency-Key') required String idempotencyKey,
    @Path('month') required String month,
    @Body() CopyFixedItemsRequest? body,
  });
}
