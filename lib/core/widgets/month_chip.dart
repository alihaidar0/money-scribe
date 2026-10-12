import 'package:flutter/material.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';

/// The pill "October 2026 ⌄" that opens the month picker. Arrows are only for
/// the Overview; every other screen chooses a month from this chip. Without
/// [onPressed] it only shows the month, with no chevron, for a screen whose
/// month cannot be changed.
class MonthChip extends StatelessWidget {
  const new({required this.month, this.onPressed, super.key});

  final YearMonth month;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = context.monthFormatter.format(month);
    final onPressed = this.onPressed;

    return Semantics(
      button: onPressed != null,
      label: onPressed == null
          ? text
          : context.l10n.monthChipLabel(month: text),
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                20,
                8,
                onPressed == null ? 20 : 12,
                8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(text, style: theme.textTheme.titleMedium),
                  ),
                  if (onPressed != null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
