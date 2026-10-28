import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/widgets/day_wheel_sheet.dart';

/// A field that shows a day of the month and opens a scroll wheel of the days
/// [min] to [max] when it is tapped. [captionFor] says something about the day
/// under the wheel, such as the part of the month it belongs to.
class DayPickerField extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.captionFor,
    super.key,
  });

  final String label;
  final int value;

  /// The first and the last day that can be chosen.
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String Function(int day)? captionFor;

  Future<void> _pick(BuildContext context) async {
    final day = await showDayWheelSheet(
      context,
      title: label,
      value: value,
      min: min,
      max: max,
      captionFor: captionFor,
    );
    if (day != null) onChanged(day);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      value: '$value',
      excludeSemantics: true,
      onTap: () => _pick(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pick(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(LucideIcons.calendarDays),
          ),
          child: Text('$value', style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );
  }
}
