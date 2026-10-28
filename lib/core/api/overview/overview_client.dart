// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/currency.dart';
import '../models/overview.dart';

part 'overview_client.g.dart';

@RestApi()
abstract class OverviewClient {
  factory OverviewClient(Dio dio, {String? baseUrl}) = _OverviewClient;

  /// The Overview of a month.
  ///
  /// What came in, what went out and what is left in one `currency`, for the whole month (`total`) and, for a month paid twice, for each part (`first_part`, `second_part`; both `null` for a month paid once). A month paid twice follows the pay cycle of the Settings pay days (20 and 5 until set): the first part runs from the 20th to the 4th of the next month, the second from the 5th to the 19th, and the month is both together. A month paid once is the calendar month. `balance` is `salary` + `recurring_income` + `income_transactions` - `fixed_costs` - `purchases` + `debt_repayments_received` - `debt_repayments_made`. The salary and the fixed items are those of the saved month and count only when its currency is `currency`; otherwise those lines are 0 and `currencies` lists the salary month's currency. Expenses and repayments count by their calendar `date`, an income by the part it joined (its `part`, else the nearest pay day); creating a debt is not a movement, a repayment is. `has_data` is true when the month has a saved salary month or any transaction or repayment, in any currency. A month with nothing is `200` with every line `0.00`. Never paginated or cached. An unsupported `currency` is `400` `invalid_choice`.
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
  @GET('/api/v1/overview/months/{month}/')
  Future<Overview> overviewMonth({
    @Path('month') required String month,
    @Query('currency') Currency? currency,
  });
}
