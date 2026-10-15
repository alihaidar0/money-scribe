import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/features/settings/domain/default_currency_repository.dart';

/// A default currency that lives in memory, until the server exists. It
/// follows the demo panel's slow, failing and offline answers.
class FakeDefaultCurrencyRepository implements DefaultCurrencyRepository {
  new({required this._demo});

  final DemoController _demo;

  Currency _currency = Currency.rub;

  @override
  Future<Currency> load() async {
    await _demo.simulateRequest();
    return _currency;
  }

  @override
  Future<void> save(Currency currency) async {
    await _demo.simulateSave();
    _currency = currency;
  }
}
