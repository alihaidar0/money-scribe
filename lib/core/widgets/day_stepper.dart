import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';

/// A label with a minus button, the day of the month and a plus button.
class DayStepper extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.caption,
    super.key,
  });

  final String label;
  final String? caption;
  final int value;

  /// The first and the last day that can be chosen.
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyLarge),
              if (caption != null)
                Text(
                  caption!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: l10n.decrease,
          icon: const Icon(LucideIcons.minus),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$value',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        IconButton.filledTonal(
          tooltip: l10n.increase,
          icon: const Icon(LucideIcons.plus),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
