import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/features/salary/domain/salary_defaults.dart';
import 'package:money_scribe/features/salary/domain/salary_month.dart';

/// Where the saved months come from: the server. Every method can throw a
/// `DataException` when the server cannot be reached or fails.
abstract interface class SalaryRepository {
  /// Emits when the saved months may have changed without the app saving
  /// them, so a screen showing one loads it again.
  Stream<void> get changes;

  /// The saved salary of [month], or `null` when none was saved yet.
  Future<SalaryMonth?> month(YearMonth month);

  /// How a month that was not saved yet starts.
  Future<SalaryDefaults> defaults();

  /// Saves [month], replacing the saved one of the same month.
  Future<void> save(SalaryMonth month);
}
