// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/export_request_request.dart';

part 'exports_client.g.dart';

@RestApi()
abstract class ExportsClient {
  factory ExportsClient(Dio dio, {String? baseUrl}) = _ExportsClient;

  /// Export the data as CSV.
  ///
  /// Needs the account password (it is `POST` so the password is never in a URL). `kinds` is 1 to 3 different values of `transactions`, `debts`, `salary_months`; `from` and `to` are optional inclusive days (both left out is all time). One kind is answered as `text/csv; charset=utf-8`, several as `application/zip` with `transactions.csv`, `debts.csv` and `salary_months.csv`. The file name is fixed and has no personal data and no date. Each file is UTF-8 with a byte order mark, a fixed header row, `,`, `\"` quoting, CRLF line ends, oldest first; dates are `YYYY-MM-DD`, months `YYYY-MM`, amounts decimal strings of the currency's digits, an empty cell means none. A text cell that a spreadsheet could read as a formula gets one `'` in front; the figures and the JSON cells are never changed. Nothing in the period is a file with the header row only. The export is rate limited (5 an hour), a `data_exported` security event is written and the owner gets an email that an export was made. Errors: `400` `invalid_choice`, `min_length` or `max_length` on `kinds`, `invalid_date_range` on `to`, `date_out_of_range`, `required` or `invalid_password` on `current_password`; `429` `password_attempts_exceeded` (shared with the password change) or `throttled`; `503` `service_unavailable` while the limit store is down.
  @POST('/api/v1/exports/')
  @DioResponseType(ResponseType.stream)
  Stream<String> exportCreate({@Body() required ExportRequestRequest body});
}
