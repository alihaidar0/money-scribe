import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';

/// The pill "‹ October 2026 ›" that goes to the previous or next month. It is
/// the only place with arrows: other screens choose a month from a chip. The
/// arrows mirror in right-to-left languages, and the next one is off once the
/// month of today is shown.
class MonthSwitcher extends StatelessWidget {
  const new({
    required this.month,
    required this.canStepForward,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final YearMonth month;
  final bool canStepForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.previousMonth,
              icon: const Icon(LucideIcons.chevronLeftDir),
              onPressed: onPrevious,
            ),
            Flexible(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  context.monthFormatter.format(month),
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.nextMonth,
              icon: const Icon(LucideIcons.chevronRightDir),
              onPressed: canStepForward ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}
