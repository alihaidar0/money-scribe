// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/currency.dart';
import '../models/debts_report.dart';
import '../models/kind.dart';
import '../models/month_report.dart';
import '../models/paginated_day_total_list.dart';

part 'reports_client.g.dart';

@RestApi()
abstract class ReportsClient {
  factory ReportsClient(Dio dio, {String? baseUrl}) = _ReportsClient;

  /// The total of each day.
  ///
  /// One item per day that has transactions, newest day first, each with its currencies inside: `totals` has one `{currency, total}` per currency, ordered by currency code, where `total` is income minus expenses of that day in that currency. A day always arrives complete: `limit` (50 by default, 100 at most) counts days, and `next` follows to the older ones. `date_from` and `date_to` are optional and there is no limit on the span. It takes the filters of the transaction list except `search`, which is not a parameter of this operation. The list and the totals read in step: the same order, the same filters. A day with no transaction has no item. A total past the largest amount is `400` `invalid_amount`.
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
  @GET('/api/v1/reports/day-totals/')
  Future<PaginatedDayTotalList> reportDayTotals({
    @Query('account_id') List<String>? accountId,
    @Query('category_id') List<String>? categoryId,
    @Query('cursor') String? cursor,
    @Query('date_from') DateTime? dateFrom,
    @Query('date_to') DateTime? dateTo,
    @Query('kind') Kind? kind,
    @Query('limit') int? limit,
  });

  /// The debts report.
  ///
  /// `by_currency` has one block per currency that has unsettled debts, ordered by currency code: what the person is owed (`owed_to_you`, the `remaining` of unsettled debts lent), what they owe (`you_owe`) and the unsettled debts themselves, `overdue` (by `due_date`, the oldest first) and `open` (by `due_date`, those with none last). Settled debts are not listed. `has_data` is true when the person has any debt, settled or not. The `status` is counted in the person's own day; `today` replaces it. Never paginated (a person has at most 500 debts).
  ///
  /// [today] - A calendar day (`YYYY-MM-DD`) that replaces the person's current day when the `status` is worked out. The app leaves it out.
  @GET('/api/v1/reports/debts/')
  Future<DebtsReport> reportDebts({@Query('today') DateTime? today});

  /// The month report: spending by category.
  ///
  /// Transactions only, in one `currency`: `income_transactions` is the income transactions dated in the month (the salary and the recurring income are not included; the Overview has them) and `purchases` is the expense transactions (the fixed costs are not included). `categories` is the spending by category, the biggest first, and adds up to `purchases`. A month paid twice follows the pay cycle of the Settings pay days and also has `first_part` and `second_part`: expenses are cut by their own `date`, and an income joins the part it was put on or the part with the nearest pay day; a month paid once is the calendar month and has `null` for both. Whether the month has parts follows the saved salary month, or the Settings payment mode for a month never saved. A month with nothing is `200` with zero totals, no categories and `has_data` false. Never paginated or cached. An unsupported `currency` is `400` `invalid_choice`.
  ///
  /// [currency] - The currency of every amount in the answer. Left out, it is the Settings default currency (`RUB` until set). Data in other currencies is not in the figures; `currencies` lists them.
  ///
  /// * `RUB` - RUB.
  /// * `USD` - USD.
  /// * `EUR` - EUR.
  /// * `GBP` - GBP.
  /// * `TRY` - TRY.
  /// * `SAR` - SAR.
  /// * `AED` - AED.
  /// * `EGP` - EGP.
  /// * `JPY` - JPY.
  /// * `KWD` - KWD.
  ///
  /// [month] - The month, `YYYY-MM`, from 2000-01 to 2099-12. Any other key is not a route (a plain `404`).
  @GET('/api/v1/reports/months/{month}/')
  Future<MonthReport> reportMonth({
    @Path('month') required String month,
    @Query('currency') Currency? currency,
  });
}
