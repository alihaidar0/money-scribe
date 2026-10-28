import 'package:flutter/material.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/widgets/amount_field.dart';
import 'package:money_scribe/core/widgets/app_text_field.dart';
import 'package:money_scribe/core/widgets/day_picker_field.dart';
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
/// for the day of [month] the item falls on, picked on a wheel, and which part
/// the item is paid from: by default the part that was paid most recently
/// before that day, going by the days the payments are received on
/// ([firstPayDay] and [secondPayDay]), or the one the person chooses. A new
/// item starts on the pay day of [part]. Closes with what was done, or with
/// `null` when dismissed.
Future<FixedItemSheetResult?> showFixedItemSheet(
  BuildContext context, {
  required YearMonth month,
  required Currency currency,
  required bool twoPayments,
  required int firstPayDay,
  required int secondPayDay,
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
      month: month,
      currency: currency,
      twoPayments: twoPayments,
      firstPayDay: firstPayDay,
      secondPayDay: secondPayDay,
      part: item?.part ?? part,
      item: item,
    ),
  );
}

/// How the part an item is paid from is chosen.
enum _PartChoice {
  /// The part follows the day of the item.
  automatic,
  first,
  second,
}

class _FixedItemSheet extends StatefulWidget {
  const new({
    required this.month,
    required this.currency,
    required this.twoPayments,
    required this.firstPayDay,
    required this.secondPayDay,
    required this.part,
    required this.item,
  });

  final YearMonth month;
  final Currency currency;
  final bool twoPayments;
  final int firstPayDay;
  final int secondPayDay;
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
  // A saved day past the end of the month (31 in September) counts as the last
  // day, as the server says.
  late int _day =
      (widget.item?.day ??
              (widget.part == FixedItemPart.first
                  ? widget.firstPayDay
                  : widget.secondPayDay))
          .clamp(1, widget.month.daysInMonth);

  /// An item whose part is the one its day gives is paid automatically; one
  /// the person put in another part, or with no day, keeps that part.
  late _PartChoice _choice = _initialChoice();

  _PartChoice _initialChoice() {
    final item = widget.item;
    if (item == null || item.part == _partOfDay(_day)) {
      return _PartChoice.automatic;
    }
    return item.part == FixedItemPart.first
        ? _PartChoice.first
        : _PartChoice.second;
  }

  FixedItemPart _partOfDay(int day) {
    return FixedItemPart.ofDay(
      day,
      firstPayDay: widget.firstPayDay,
      secondPayDay: widget.secondPayDay,
    );
  }

  /// The part the item is paid from when it falls on [day].
  FixedItemPart _partFor(int day) {
    return switch (_choice) {
      _PartChoice.automatic => _partOfDay(day),
      _PartChoice.first => FixedItemPart.first,
      _PartChoice.second => FixedItemPart.second,
    };
  }

  /// When the payment of [part] is received.
  String _paidOn(FixedItemPart part) {
    final l10n = context.l10n;
    return part == FixedItemPart.first
        ? l10n.firstPaymentPaidOnDay(day: widget.firstPayDay)
        : l10n.secondPaymentPaidOnDay(day: widget.secondPayDay);
  }

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
    day: widget.twoPayments ? _day : null,
    part: widget.twoPayments ? _partFor(_day) : widget.part,
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
              DayPickerField(
                label: l10n.fixedItemDayLabel,
                value: _day,
                min: 1,
                max: widget.month.daysInMonth,
                onChanged: (day) => setState(() => _day = day),
                captionFor: (day) => _paidOn(_partFor(day)),
              ),
              const SizedBox(height: 16),
              Text(l10n.fixedItemPartLabel, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              PillSegmentedButton<_PartChoice>(
                segments: [
                  ButtonSegment(
                    value: _PartChoice.automatic,
                    label: Text(l10n.fixedItemPartAutomatic),
                  ),
                  ButtonSegment(
                    value: _PartChoice.first,
                    label: Text(l10n.partFirst),
                  ),
                  ButtonSegment(
                    value: _PartChoice.second,
                    label: Text(l10n.partSecond),
                  ),
                ],
                selected: {_choice},
                onSelectionChanged: (selection) =>
                    setState(() => _choice = selection.first),
              ),
              const SizedBox(height: 8),
              Text(
                _paidOn(_partFor(_day)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
