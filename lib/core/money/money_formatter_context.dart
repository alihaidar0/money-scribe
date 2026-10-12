import 'package:flutter/widgets.dart';
import 'package:money_scribe/core/dates/day_formatter.dart';
import 'package:money_scribe/core/dates/month_formatter.dart';
import 'package:money_scribe/core/money/money_formatter.dart';

extension FormattersContext on BuildContext {
  /// Formats amounts in the language shown. Always show an amount through it.
  MoneyFormatter get moneyFormatter {
    return MoneyFormatter(Localizations.localeOf(this));
  }

  /// Formats months in the language shown.
  MonthFormatter get monthFormatter {
    return MonthFormatter(Localizations.localeOf(this));
  }

  /// Formats days in the language shown.
  DayFormatter get dayFormatter {
    return DayFormatter(Localizations.localeOf(this));
  }
}
