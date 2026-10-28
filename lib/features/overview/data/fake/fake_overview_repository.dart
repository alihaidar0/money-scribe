import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/network/data_change.dart';
import 'package:money_scribe/features/overview/data/fake/overview_seed.dart';
import 'package:money_scribe/features/overview/domain/debt_choice.dart';
import 'package:money_scribe/features/overview/domain/month_overview.dart';
import 'package:money_scribe/features/overview/domain/overview_repository.dart';

/// An overview made of invented figures, until the server exists. It follows
/// the demo panel: no data (the first launch), one payment or two, slow,
/// failing or offline.
class FakeOverviewRepository implements OverviewRepository {
  new({required this._demo});

  final DemoController _demo;

  @override
  Stream<DataChange> get changes =>
      _demo.dataChangesWithSchedules.map((_) => DataChange.replaced);

  @override
  Future<MonthOverview?> month(YearMonth month) async {
    await _demo.simulateRequest();
    if (_demo.settings.scenario == DemoScenario.empty) return null;
    return OverviewSeed.month(month, _demo.paymentModeOf(month));
  }

  @override
  Future<List<DebtChoice>> debtsToRepay() async {
    await _demo.simulateRequest();
    if (_demo.settings.scenario == DemoScenario.empty) return const [];
    return OverviewSeed.debtsToRepay();
  }
}
