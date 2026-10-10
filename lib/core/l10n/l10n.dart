import 'package:flutter/widgets.dart';
import 'package:money_scribe/core/l10n/generated/app_localizations.dart';

export 'package:money_scribe/core/l10n/generated/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  /// The translated strings for the current locale.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
