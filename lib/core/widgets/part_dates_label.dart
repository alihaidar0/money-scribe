import 'package:flutter/widgets.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/core/payments/period_scope.dart';

/// A part of a month with the days it covers, such as "Part 2 · 5 Nov – 19
/// Nov": what the screens call a part of a month paid in two payments. [part]
/// is [PeriodScope.firstPart] or [PeriodScope.secondPart]; [range] comes from
/// `PayCycle.rangeOf`. A year is added to a day that is not in this year.
String partDatesLabel(
  BuildContext context, {
  required PeriodScope part,
  required PayPeriod range,
  required DateTime today,
}) {
  final l10n = context.l10n;
  final days = context.dayFormatter;
  return l10n.partDatesLabel(
    part: part == PeriodScope.firstPart ? l10n.partFirst : l10n.partSecond,
    from: days.formatDate(range.start, today: today),
    to: days.formatDate(range.end, today: today),
  );
}
