import 'package:dio/dio.dart';
import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/call_api.dart';
import 'package:money_scribe/core/network/data_change.dart';
import 'package:money_scribe/features/overview/data/remote/overview_wire.dart';
import 'package:money_scribe/features/overview/domain/debt_choice.dart';
import 'package:money_scribe/features/overview/domain/month_overview.dart';
import 'package:money_scribe/features/overview/domain/overview_repository.dart';

/// The Overview on the server: the real [OverviewRepository].
///
/// Every call asks for the default currency of the account, and the amounts
/// are in it; records in other currencies are not in them, and the overview
/// says that some exist. The server keeps the years 2000 to 2099, so a month
/// outside them has no data and is not asked.
class RemoteOverviewRepository implements OverviewRepository {
  new({
    required this._overview,
    required this._reports,
    required this._defaultCurrency,
    Stream<void> changes = const Stream<void>.empty(),
  }) : _saved = changes;

  /// The calls over [dio], which carries the token of the session and renews
  /// it. [defaultCurrency] is the one the settings of the account hold.
  factory create({
    required Dio dio,
    required Future<Currency> Function() defaultCurrency,
    Stream<void> changes = const Stream<void>.empty(),
  }) {
    return RemoteOverviewRepository(
      overview: api.OverviewClient(dio),
      reports: api.ReportsClient(dio),
      defaultCurrency: defaultCurrency,
      changes: changes,
    );
  }

  final api.OverviewClient _overview;
  final api.ReportsClient _reports;
  final Future<Currency> Function() _defaultCurrency;

  final Stream<void> _saved;

  /// The server does not push changes. What this device saves is announced by
  /// the stream it was given, so the screen loads the figures again, silently.
  @override
  Stream<DataChange> get changes => _saved.map((_) => DataChange.saved);

  @override
  Future<MonthOverview?> month(YearMonth month) async {
    if (month.year < 2000 || month.year > 2099) return null;
    final currency = await _defaultCurrency();
    final wire = await callApi(
      () => _overview.overviewMonth(
        month: month.param,
        currency: OverviewWire.currencyToQuery(currency),
      ),
      _map,
    );
    return OverviewWire.overview(wire, month);
  }

  @override
  Future<List<DebtChoice>> debtsToRepay() async {
    final wire = await callApi(_reports.reportDebts, _map);
    return OverviewWire.debtChoices(wire);
  }

  Exception _map(ApiFailure failure) => failure.toDataException();
}
