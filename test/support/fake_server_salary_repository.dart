import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/salary/data/fake/fake_salary_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_calculator.dart';
import 'package:money_scribe/features/salary/domain/salary_defaults.dart';
import 'package:money_scribe/features/salary/domain/salary_figures.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';

/// A salary repository that answers the way the server does: every saved month
/// comes with the figures the server calculated, which a test can make differ
/// from what the app would calculate to see that the server's are the ones
/// shown. The months themselves are [inner]'s.
class FakeServerSalaryRepository implements SalaryRepository {
  new(this.inner);

  final FakeSalaryRepository inner;

  /// The lines the server calculated, given what the app calculates from the
  /// same inputs. By default the same.
  SalaryResult Function(SalaryResult calculated) resultOf = (result) => result;

  /// The balances the server calculated for a month. By default the pay of
  /// each payment, as for a month with no fixed items.
  SalaryBalances Function(SalaryMonth month, SalaryResult result) balancesOf =
      (month, result) => SalaryBalances(
        first: result.payments.first,
        second: result.payments.length == 2 ? result.payments.last : null,
        month: result.totalAfterTax,
      );

  /// While `true`, reading a month fails as a lost connection does.
  bool failReads = false;

  /// How many times a single month was read.
  int monthReads = 0;

  @override
  Stream<void> get changes => inner.changes;

  @override
  Future<SalaryMonth?> month(YearMonth month) async {
    monthReads++;
    if (failReads) throw const NoConnectionException();
    final saved = await inner.month(month);
    return saved == null ? null : _withFigures(saved);
  }

  @override
  Future<List<SalaryMonth>> savedMonths() async {
    return [for (final month in await inner.savedMonths()) _withFigures(month)];
  }

  @override
  Future<SalaryDefaults> defaults(YearMonth month) => inner.defaults(month);

  @override
  Future<SalaryMonth> save(SalaryMonth month) async {
    return _withFigures(await inner.save(month));
  }

  @override
  Future<void> delete(YearMonth month, {required int version}) {
    return inner.delete(month, version: version);
  }

  SalaryMonth _withFigures(SalaryMonth month) {
    final calculation = SalaryCalculator.calculate(month.inputs);
    if (calculation is! SalaryComputed) return month;

    final result = resultOf(calculation.result);
    return SalaryMonth(
      month: month.month,
      inputs: month.inputs,
      firstPayDay: month.firstPayDay,
      secondPayDay: month.secondPayDay,
      version: month.version,
      figures: SalaryFigures(
        result: result,
        balances: balancesOf(month, result),
      ),
    );
  }
}
