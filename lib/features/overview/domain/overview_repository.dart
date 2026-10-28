import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/network/data_change.dart';
import 'package:money_scribe/features/overview/domain/debt_choice.dart';
import 'package:money_scribe/features/overview/domain/month_overview.dart';

/// Where the overview comes from: the server. Every method can throw a
/// `DataException` when the server cannot be reached or fails.
abstract interface class OverviewRepository {
  /// Emits whenever what the overview is made of may have changed, so the
  /// screen loads it again; the value says whether it does so silently.
  Stream<DataChange> get changes;

  /// The overview of [month], or `null` when the account has no data yet (the
  /// first launch).
  Future<MonthOverview?> month(YearMonth month);

  /// The debts a repayment can be added to.
  Future<List<DebtChoice>> debtsToRepay();
}
