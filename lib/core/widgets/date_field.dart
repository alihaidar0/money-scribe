import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';

/// A field that shows a day and opens the date picker when it is tapped. An
/// optional day (with [onCleared]) can be taken away again with the clear
/// button. [today] is the day of the device, so a day in another year shows
/// its year.
class DateField extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.today,
    required this.onChanged,
    this.onCleared,
    this.firstDate,
    this.lastDate,
    super.key,
  });

  final String label;
  final DateTime? value;
  final DateTime today;
  final ValueChanged<DateTime> onChanged;

  /// Makes the day optional: shown as a clear button while a day is set.
  final VoidCallback? onCleared;

  /// The earliest and the latest day that can be chosen.
  final DateTime? firstDate;
  final DateTime? lastDate;

  Future<void> _pick(BuildContext context) async {
    final first = firstDate ?? DateTime(2000);
    final last = lastDate ?? DateTime(2100);
    var initial = value ?? today;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final chosen = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (chosen != null) {
      onChanged(DateTime(chosen.year, chosen.month, chosen.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    final text = value == null
        ? ''
        : context.dayFormatter.formatDate(value, today: today);

    return Semantics(
      button: true,
      label: label,
      value: text,
      excludeSemantics: true,
      onTap: () => _pick(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pick(context),
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: value != null && onCleared != null
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: context.l10n.clearDateAction,
                    onPressed: onCleared,
                  )
                : const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );
  }
}
