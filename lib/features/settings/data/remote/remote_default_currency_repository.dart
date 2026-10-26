// The contract also has a `Currency` of its own (money data); this file uses
// the app's `Currency` and the settings' `CurrencyEnum`.
import 'package:money_scribe/core/api/export.dart' hide Currency;
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/features/settings/data/remote/remote_settings.dart';
import 'package:money_scribe/features/settings/domain/default_currency_repository.dart';

/// The default currency on the server: the real [DefaultCurrencyRepository].
class RemoteDefaultCurrencyRepository implements DefaultCurrencyRepository {
  new(this._settings);

  final RemoteSettings _settings;

  @override
  Future<Currency> load() async {
    final settings = await _settings.read();
    // A currency the app does not know is an answer that breaks the contract.
    return Currency.tryFromCode(settings.defaultCurrency.json ?? '') ??
        (throw const ServerException());
  }

  @override
  Future<void> save(Currency currency) async {
    final code = CurrencyEnum.fromJson(currency.code);
    if (code == CurrencyEnum.$unknown) throw const ServerException();
    await _settings.update(defaultCurrency: code);
  }
}
