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

  /// Every saved month, the newest first.
  Future<List<SalaryMonth>> savedMonths();

  /// How [month], which was not saved yet, starts: the figures of the most
  /// recent other saved month, under the account's pay schedule.
  Future<SalaryDefaults> defaults(YearMonth month);

  /// Saves [month] and returns it as the server holds it, under its new
  /// version. A month with a [SalaryMonth.version] replaces the saved one only
  /// if that is still the saved version; one without a version creates the
  /// month only if none exists. Otherwise it throws a `StaleRecordException`
  /// and changes nothing.
  Future<SalaryMonth> save(SalaryMonth month);

  /// Deletes the saved salary of [month] if it is still at [version], and with
  /// it the fixed items of the month. A month that is not saved is already
  /// gone and does nothing; a month saved at another version throws a
  /// `StaleRecordException`.
  Future<void> delete(YearMonth month, {required int version});
}
