// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/import_request.dart';
import '../models/import_result.dart';

part 'imports_client.g.dart';

@RestApi()
abstract class ImportsClient {
  factory ImportsClient(Dio dio, {String? baseUrl}) = _ImportsClient;

  /// Import rows of one dataset.
  ///
  /// The app reads the CSV and sends rows as JSON; the server never parses an uploaded file. `dataset` is `transactions`, `debts` or `salary_months`, `rows` is 1 to 500 rows, each with its line number `row` (a positive whole number, unique in the call) and the fields of the dataset named like the CSV columns. Every row goes through the rules of a single create (a `PUT` for a salary month) and gets the same codes. The call is one database transaction: a row that passes is written, a row that fails is skipped and reported in `problems` (the first problem of the row), and the answer is always `200`. An import never creates an account or a category (`unknown_category`, `unknown_account`), never reads an id, and never overwrites: a row equal to an existing record is a `duplicate`, counted by multiplicity, and a salary month that exists is a `duplicate`. The record caps apply (`transaction_limit_reached`, `debt_limit_reached`, `repayment_limit_reached`, `fixed_item_limit_reached`). A real import needs an `Idempotency-Key`; with `dry_run` `true` nothing is written or stored and no key is needed. A call that writes at least one row records a `data_imported` security event. Limits: 500 rows and 1 MB a call, 120 calls an hour; `503` `service_unavailable` while the limit store is down.
  ///
  /// [idempotencyKey] - Required unless `dry_run` is `true`: a random id, once per user action, as a quoted string of 16 to 64 letters, digits, hyphens or underscores. The same key with the same body returns the first answer with `Idempotent-Replayed: true`; another body under the same key is `422`.
  @POST('/api/v1/imports/')
  Future<ImportResult> importCreate({
    @Header('Idempotency-Key') String? idempotencyKey,
    @Body() ImportRequest? body,
  });
}
