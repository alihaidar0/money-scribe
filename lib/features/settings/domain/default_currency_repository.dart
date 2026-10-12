import 'package:money_scribe/core/money/currency.dart';

/// Where the default currency is kept: on the server. Every method can throw
/// a `DataException` when the server cannot be reached or fails.
abstract interface class DefaultCurrencyRepository {
  /// The currency new amounts are in.
  Future<Currency> load();

  /// Saves the currency new amounts are in.
  Future<void> save(Currency currency);
}
