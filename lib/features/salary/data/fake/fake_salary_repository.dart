import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/salary/data/fake/salary_seed.dart';
import 'package:money_scribe/features/salary/domain/salary_defaults.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';

/// Saved salaries made of invented figures, until the server exists. It follows
/// the demo panel: no data, one payment or two, slow, failing or offline. What
/// the app saves is kept in memory for as long as it runs.
class FakeSalaryRepository implements SalaryRepository {
  new({required this._demo});

  final DemoController _demo;

  /// What was saved since the app started; it replaces the seed.
  final _saved = <YearMonth, SalaryMonth>{};

  @override
  Stream<void> get changes => _demo.dataChanges;

  @override
  Future<SalaryMonth?> month(YearMonth month) async {
    await _demo.simulateRequest();
    final saved = _saved[month];
    if (saved != null) return saved;
    if (_demo.settings.scenario == DemoScenario.empty) return null;
    return SalarySeed.month(month, _demo.settings.paymentMode);
  }

  @override
  Future<SalaryDefaults> defaults() async {
    return SalaryDefaults(paymentMode: _demo.settings.paymentMode);
  }

  @override
  Future<void> save(SalaryMonth month) async {
    await _demo.simulateSave();
    _saved[month.month] = month;
  }
}
