import 'package:dio/dio.dart';
import 'package:money_scribe/core/api/export.dart' as api;
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/network/call_api.dart';
import 'package:money_scribe/core/network/data_change.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/features/reports/data/remote/reports_wire.dart';
import 'package:money_scribe/features/reports/domain/debts_report.dart';
import 'package:money_scribe/features/reports/domain/month_report.dart';
import 'package:money_scribe/features/reports/domain/reports_repository.dart';

/// The Reports on the server: the real [ReportsRepository].
///
/// A month is read from two calls made together, the Overview and the month
/// report, so the income and the spending of the reports are the Overview's
/// and the categories add up to them. Every call asks for the default currency
/// of the account; records in other currencies are not in the figures, and
/// the report says that some exist. The server keeps the years 2000 to 2099,
/// so a month outside them has no data and is not asked.
class RemoteReportsRepository implements ReportsRepository {
  new({
    required this._overview,
    required this._reports,
    required this._defaultCurrency,
    required this._partsCycle,
    Stream<void> changes = const Stream<void>.empty(),
  }) : _saved = changes;

  /// The calls over [dio], which carries the token of the session and renews
  /// it. [defaultCurrency] is the one the settings of the account hold, and
  /// [partsCycle] the pay days of its settings, which cut a month paid twice
  /// into parts.
  factory create({
    required Dio dio,
    required Future<Currency> Function() defaultCurrency,
    required Future<PayCycle> Function() partsCycle,
    Stream<void> changes = const Stream<void>.empty(),
  }) {
    return RemoteReportsRepository(
      overview: api.OverviewClient(dio),
      reports: api.ReportsClient(dio),
      defaultCurrency: defaultCurrency,
      partsCycle: partsCycle,
      changes: changes,
    );
  }

  final api.OverviewClient _overview;
  final api.ReportsClient _reports;
  final Future<Currency> Function() _defaultCurrency;
  final Future<PayCycle> Function() _partsCycle;

  final Stream<void> _saved;

  /// The server does not push changes. What this device saves is announced by
  /// the stream it was given, so the screen loads the figures again, silently.
  @override
  Stream<DataChange> get changes => _saved.map((_) => DataChange.saved);

  @override
  Future<MonthReport?> month(YearMonth month) async {
    if (month.year < 2000 || month.year > 2099) return null;
    final currency = ReportsWire.currencyToQuery(await _defaultCurrency());
    final answers = await Future.wait<Object>([
      callApi(
        () => _overview.overviewMonth(month: month.param, currency: currency),
        _map,
      ),
      callApi(
        () => _reports.reportMonth(month: month.param, currency: currency),
        _map,
      ),
    ]);
    return ReportsWire.month(
      overview: answers[0] as api.Overview,
      report: answers[1] as api.MonthReport,
      month: month,
      partsCycle: await _partsCycle(),
    );
  }

  @override
  Future<DebtsReport> debts() async {
    final currency = await _defaultCurrency();
    final wire = await callApi(_reports.reportDebts, _map);
    return ReportsWire.debts(wire, currency);
  }

  Exception _map(ApiFailure failure) => failure.toDataException();
}
