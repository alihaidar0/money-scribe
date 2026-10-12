import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/salary/data/fake/salary_seed.dart';
import 'package:money_scribe/features/salary/domain/salary_defaults.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';

/// Saved salaries made of invented figures, until the server exists. It follows
/// the demo panel: no data, one payment or two, slow, failing or offline. What
/// the app saves or deletes is kept in memory for as long as it runs.
class FakeSalaryRepository implements SalaryRepository {
  new({required this._demo});

  final DemoController _demo;

  /// What was saved since the app started; it replaces the seed.
  final _saved = <YearMonth, SalaryMonth>{};

  /// The seeded months that were deleted since the app started.
  final _deleted = <YearMonth>{};

  @override
  Stream<void> get changes => _demo.dataChanges;

  @override
  Future<SalaryMonth?> month(YearMonth month) async {
    await _demo.simulateRequest();
    return _find(month);
  }

  @override
  Future<List<SalaryMonth>> savedMonths() async {
    await _demo.simulateRequest();
    final months = {
      if (_demo.settings.scenario != DemoScenario.empty) ...SalarySeed.months,
      ..._saved.keys,
    }.toList()..sort((a, b) => b.compareTo(a));

    return [for (final month in months) ?_find(month)];
  }

  @override
  Future<SalaryDefaults> defaults() async {
    return SalaryDefaults(paymentMode: _demo.settings.paymentMode);
  }

  @override
  Future<void> save(SalaryMonth month) async {
    await _demo.simulateSave();
    _saved[month.month] = month;
    _deleted.remove(month.month);
  }

  @override
  Future<void> delete(YearMonth month) async {
    await _demo.simulateSave();
    _saved.remove(month);
    _deleted.add(month);
  }

  /// The saved month, without waiting for the server.
  SalaryMonth? _find(YearMonth month) {
    if (_deleted.contains(month)) return null;
    final saved = _saved[month];
    if (saved != null) return saved;
    if (_demo.settings.scenario == DemoScenario.empty) return null;
    return SalarySeed.month(month, _demo.settings.paymentMode);
  }
}
