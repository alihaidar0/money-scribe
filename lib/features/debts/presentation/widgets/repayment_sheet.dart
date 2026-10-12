import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/widgets/amount_field.dart';
import 'package:money_scribe/core/widgets/confirm_dialogs.dart';
import 'package:money_scribe/core/widgets/date_field.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';

/// What the person did in the repayment sheet.
sealed class RepaymentSheetResult {
  const new();
}

/// Save: the repayment as it was typed.
final class RepaymentSheetSaved extends RepaymentSheetResult {
  const new(this.draft);

  final RepaymentDraft draft;
}

/// Delete, after the person confirmed it.
final class RepaymentSheetDeleted extends RepaymentSheetResult {
  const new();
}

/// DB-4 and DB-5: the bottom sheet that adds a repayment, or with [repayment]
/// changes or deletes it. It cannot be more than [maxAmount], what is still to
/// be repaid (with the repayment's own amount added back when changing it).
/// Closes with what was done, or with `null` when dismissed.
Future<RepaymentSheetResult?> showRepaymentSheet(
  BuildContext context, {
  required Currency currency,
  required Money maxAmount,
  required DateTime today,
  Repayment? repayment,
}) {
  return showModalBottomSheet<RepaymentSheetResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Over the navigation bar too, which stays dimmed and inactive.
    useRootNavigator: true,
    builder: (sheetContext) => _RepaymentSheet(
      currency: currency,
      maxAmount: maxAmount,
      today: today,
      repayment: repayment,
    ),
  );
}

class _RepaymentSheet extends StatefulWidget {
  const new({
    required this.currency,
    required this.maxAmount,
    required this.today,
    required this.repayment,
  });

  final Currency currency;
  final Money maxAmount;
  final DateTime today;
  final Repayment? repayment;

  @override
  State<_RepaymentSheet> createState() => _RepaymentSheetState();
}

class _RepaymentSheetState extends State<_RepaymentSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.repayment?.amount.toDecimalString() ?? '',
  );

  /// The amount as typed. The field shows it grouped when it is not being
  /// edited, so the text of the controller is not what is parsed.
  late String _amountText = _amount.text;
  late DateTime _date =
      widget.repayment?.date ??
      DateTime(widget.today.year, widget.today.month, widget.today.day);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  RepaymentDraft? get _draft => RepaymentDraft.tryCreate(
    amount: _amountText,
    currency: widget.currency,
    date: _date,
    maxAmount: widget.maxAmount,
  );

  Future<void> _delete() async {
    final repayment = widget.repayment;
    if (repayment == null) return;
    final l10n = context.l10n;
    final amount = context.moneyFormatter.format(repayment.amount);
    final confirmed = await confirmDelete(
      context,
      title: l10n.deleteRepaymentTitle,
      message: l10n.deleteRepaymentMessage(amount: amount),
    );
    if (confirmed && mounted) {
      Navigator.of(context).pop(const RepaymentSheetDeleted());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final draft = _draft;
    final editing = widget.repayment != null;
    final typed = Money.tryParse(_amountText, widget.currency);
    final tooHigh = typed != null && typed > widget.maxAmount;
    final invalid =
        _amountText.isNotEmpty && (typed == null || !typed.isPositive);

    return SafeArea(
      child: SingleChildScrollView(
        // Above the keyboard.
        padding: EdgeInsetsDirectional.fromSTEB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                editing ? l10n.editRepaymentTitle : l10n.addRepaymentTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            AmountField(
              controller: _amount,
              label: l10n.amountLabel,
              currency: widget.currency,
              hintText: '0.00',
              alwaysFloatLabel: true,
              style: theme.textTheme.headlineSmall,
              errorText: tooHigh
                  ? l10n.repaymentTooHigh(
                      remaining: context.moneyFormatter.format(
                        widget.maxAmount,
                      ),
                    )
                  : invalid
                  ? l10n.amountInvalid
                  : null,
              textInputAction: TextInputAction.done,
              onChanged: (text) => setState(() => _amountText = text),
            ),
            const SizedBox(height: 16),
            DateField(
              label: l10n.dateLabel,
              value: _date,
              today: widget.today,
              onChanged: (date) => setState(() => _date = date),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: editing
                  ? WrapAlignment.spaceBetween
                  : WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                if (editing)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: _delete,
                    child: Text(l10n.deleteAction),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancelAction),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: draft == null
                          ? null
                          : () =>
                                Navigator.of(context)
                                    .pop(RepaymentSheetSaved(draft)),
                      child: Text(l10n.saveAction),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
