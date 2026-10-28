import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/network/data_change.dart';
import 'package:money_scribe/features/reports/data/fake/reports_seed.dart';
import 'package:money_scribe/features/reports/domain/debts_report.dart';
import 'package:money_scribe/features/reports/domain/month_report.dart';
import 'package:money_scribe/features/reports/domain/reports_repository.dart';

/// Reports made of invented figures, until the server exists. It follows the
/// demo panel: no data, one payment or two (a month saved on the Salary screen
/// keeps its own schedule), slow, failing or offline.
class FakeReportsRepository implements ReportsRepository {
  new({required this._demo});

  final DemoController _demo;

  @override
  Stream<DataChange> get changes =>
      _demo.dataChangesWithSchedules.map((_) => DataChange.replaced);

  @override
  Future<MonthReport?> month(YearMonth month) async {
    await _demo.simulateRequest();
    if (_demo.settings.scenario == DemoScenario.empty) return null;
    return ReportsSeed.month(month, _demo.paymentModeOf(month));
  }

  @override
  Future<DebtsReport> debts() async {
    await _demo.simulateRequest();
    if (_demo.settings.scenario == DemoScenario.empty) {
      return const DebtsReport(
        owedToYou: Money.zero(Currency.rub),
        youOwe: Money.zero(Currency.rub),
      );
    }
    return ReportsSeed.debts();
  }
}
