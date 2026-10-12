import 'package:flutter/material.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';

/// SAL-4 and SAL-5: asks whether a saved [month] really changes to [target]
/// (one payment, or two). Answers `true` for Switch, `false` for Cancel or a
/// tap outside.
Future<bool> confirmPaymentModeSwitch(
  BuildContext context, {
  required PaymentMode target,
  required YearMonth month,
}) async {
  final l10n = context.l10n;
  final monthName = context.monthFormatter.format(month);
  final toOne = target == PaymentMode.onePayment;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(toOne ? l10n.switchToOneTitle : l10n.switchToTwoTitle),
      content: Text(
        toOne
            ? l10n.switchToOneMessage(month: monthName)
            : l10n.switchToTwoMessage(month: monthName),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.switchAction),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
