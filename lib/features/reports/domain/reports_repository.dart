import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/features/reports/domain/debts_report.dart';
import 'package:money_scribe/features/reports/domain/month_report.dart';

/// Where the reports come from: the server. Every method can throw a
/// `DataException` when the server cannot be reached or fails.
abstract interface class ReportsRepository {
  /// Emits whenever what the reports are made of may have changed, so the
  /// screen loads them again.
  Stream<void> get changes;

  /// The report of [month], or `null` when the account has no data yet.
  Future<MonthReport?> month(YearMonth month);

  /// Where the debts stand.
  Future<DebtsReport> debts();
}
