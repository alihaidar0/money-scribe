import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
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
  Future<SalaryDefaults> defaults(YearMonth month) async {
    // The pay schedule is the account's (the demo panel stands in for the
    // setting); the figures come from the most recent saved month.
    final paymentMode = _demo.settings.paymentMode;
    final latest = _latest();
    if (latest == null) return SalaryDefaults(paymentMode: paymentMode);

    return SalaryDefaults(
      paymentMode: paymentMode,
      firstPayDay: latest.firstPayDay,
      secondPayDay: latest.secondPayDay,
      currency: latest.inputs.baseSalary.currency,
      baseSalary: latest.inputs.baseSalary,
      foodPerDay: latest.inputs.foodPerDay,
      workingHoursInMonth: latest.inputs.workingHoursInMonth,
      taxRateBasisPoints: latest.inputs.taxRateBasisPoints,
    );
  }

  @override
  Future<SalaryMonth> save(SalaryMonth month) async {
    await _demo.simulateSave();
    final current = _find(month.month);
    // A month that was not loaded must not replace one saved elsewhere, and an
    // edit must not replace a version it has not seen.
    if (current?.version != month.version) throw const StaleRecordException();

    final saved = month.withVersion((current?.version ?? 0) + 1);
    _saved[month.month] = saved;
    _deleted.remove(month.month);
    // The other screens of the month follow how it is paid.
    _demo.setMonthPaymentMode(month.month, month.inputs.paymentMode);
    return saved;
  }

  @override
  Future<void> delete(YearMonth month, {required int version}) async {
    await _demo.simulateSave();
    final current = _find(month);
    if (current == null) return;
    if (current.version != version) throw const StaleRecordException();

    _saved.remove(month);
    _deleted.add(month);
    _demo.clearMonthPaymentMode(month);
  }

  /// The most recent saved month, without waiting for the server.
  SalaryMonth? _latest() {
    final months = {
      if (_demo.settings.scenario != DemoScenario.empty) ...SalarySeed.months,
      ..._saved.keys,
    }.toList()..sort((a, b) => b.compareTo(a));

    for (final month in months) {
      final saved = _find(month);
      if (saved != null) return saved;
    }
    return null;
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
