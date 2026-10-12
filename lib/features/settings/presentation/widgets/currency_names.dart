import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/currency.dart';

/// The name of [currency] in the language shown, such as "Russian ruble". A
/// currency without a name here shows its ISO code.
String currencyName(AppLocalizations l10n, Currency currency) {
  return switch (currency.code) {
    'RUB' => l10n.currencyNameRub,
    'USD' => l10n.currencyNameUsd,
    'EUR' => l10n.currencyNameEur,
    'GBP' => l10n.currencyNameGbp,
    'TRY' => l10n.currencyNameTry,
    'JPY' => l10n.currencyNameJpy,
    'SAR' => l10n.currencyNameSar,
    'AED' => l10n.currencyNameAed,
    'EGP' => l10n.currencyNameEgp,
    'KWD' => l10n.currencyNameKwd,
    _ => currency.code,
  };
}

/// The currency as the Settings list it: its symbol, then its name, such as
/// "₽ Russian ruble".
String currencyLabel(AppLocalizations l10n, Currency currency) {
  return '${currency.displaySymbol} ${currencyName(l10n, currency)}';
}
