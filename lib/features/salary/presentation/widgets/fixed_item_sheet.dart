import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/widgets/amount_field.dart';
import 'package:money_scribe/core/widgets/app_text_field.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/features/salary/domain/fixed_item.dart';
import 'package:money_scribe/features/salary/presentation/widgets/fixed_item_dialogs.dart';

/// What the person did in the sheet that adds or changes a fixed item.
sealed class FixedItemSheetResult {
  const new();
}

/// Save: the item as it was typed.
final class FixedItemSheetSaved extends FixedItemSheetResult {
  const new(this.draft);

  final FixedItemDraft draft;
}

/// Delete, after the person confirmed it.
final class FixedItemSheetDeleted extends FixedItemSheetResult {
  const new();
}

/// FIX-3 and FIX-4: the bottom sheet that adds a fixed item, or with [item]
/// changes it, which also offers Delete. A month paid in [twoPayments] asks
/// which part the item applies to, starting with [part] for a new one. Closes
/// with what was done, or with `null` when dismissed.
Future<FixedItemSheetResult?> showFixedItemSheet(
  BuildContext context, {
  required Currency currency,
  required bool twoPayments,
  required FixedItemPart part,
  FixedItem? item,
}) {
  return showModalBottomSheet<FixedItemSheetResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Over the navigation bar too, which stays dimmed and inactive.
    useRootNavigator: true,
    builder: (sheetContext) => _FixedItemSheet(
      currency: currency,
      twoPayments: twoPayments,
      part: item?.part ?? part,
      item: item,
    ),
  );
}

class _FixedItemSheet extends StatefulWidget {
  const new({
    required this.currency,
    required this.twoPayments,
    required this.part,
    required this.item,
  });

  final Currency currency;
  final bool twoPayments;
  final FixedItemPart part;
  final FixedItem? item;

  @override
  State<_FixedItemSheet> createState() => _FixedItemSheetState();
}

class _FixedItemSheetState extends State<_FixedItemSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.item?.name ?? '',
  );
  late final TextEditingController _amount = TextEditingController(
    text: widget.item?.amount.toDecimalString() ?? '',
  );

  /// The amount as typed. The field shows it grouped when it is not being
  /// edited, so the text of the controller is not what is parsed.
  late String _amountText = _amount.text;
  late FixedItemKind _kind = widget.item?.kind ?? FixedItemKind.expense;
  late FixedItemPart _part = widget.part;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  FixedItemDraft? get _draft => FixedItemDraft.tryCreate(
    name: _name.text,
    amount: _amountText,
    currency: widget.currency,
    kind: _kind,
    part: _part,
  );

  Future<void> _delete() async {
    final item = widget.item;
    if (item == null) return;
    final confirmed = await confirmDeleteFixedItem(context, name: item.name);
    if (confirmed && mounted) {
      Navigator.of(context).pop(const FixedItemSheetDeleted());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final draft = _draft;
    final editing = widget.item != null;

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
                editing ? l10n.editFixedItemTitle : l10n.addFixedItemTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _name,
              label: l10n.fixedItemNameLabel,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            AmountField(
              controller: _amount,
              label: l10n.fixedItemAmountLabel,
              currency: widget.currency,
              hintText: '0.00',
              alwaysFloatLabel: true,
              style: theme.textTheme.headlineSmall,
              textInputAction: TextInputAction.done,
              onChanged: (text) => setState(() => _amountText = text),
            ),
            const SizedBox(height: 16),
            PillSegmentedButton<FixedItemKind>(
              segments: [
                ButtonSegment(
                  value: FixedItemKind.income,
                  label: Text(l10n.fixedItemIncome),
                ),
                ButtonSegment(
                  value: FixedItemKind.expense,
                  label: Text(l10n.fixedItemExpense),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (selection) =>
                  setState(() => _kind = selection.first),
            ),
            if (widget.twoPayments) ...[
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  l10n.fixedItemAppliesTo,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              PillSegmentedButton<FixedItemPart>(
                segments: [
                  ButtonSegment(
                    value: FixedItemPart.first,
                    label: Text(l10n.partFirst),
                  ),
                  ButtonSegment(
                    value: FixedItemPart.second,
                    label: Text(l10n.partSecond),
                  ),
                ],
                selected: {_part},
                onSelectionChanged: (selection) =>
                    setState(() => _part = selection.first),
              ),
            ],
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
                                    .pop(FixedItemSheetSaved(draft)),
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
