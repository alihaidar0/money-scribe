import 'package:flutter/material.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/theme/money_colors.dart';

/// A pill with an icon and a label on a soft colour. Meaning is always text
/// and icon, never colour alone.
class _Badge extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 12, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Lent" or "Borrowed".
class DirectionBadge extends StatelessWidget {
  const new(this.direction, {super.key});

  final DebtDirection direction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.moneyColors;

    return switch (direction) {
      DebtDirection.lent => _Badge(
        icon: Icons.call_made,
        label: l10n.debtLent,
        background: colors.lent.container,
        foreground: colors.lent.onContainer,
      ),
      DebtDirection.borrowed => _Badge(
        icon: Icons.call_received,
        label: l10n.debtBorrowed,
        background: colors.borrowed.container,
        foreground: colors.borrowed.onContainer,
      ),
    };
  }
}

/// "Open", "Overdue" or "Settled".
class StatusBadge extends StatelessWidget {
  const new(this.status, {super.key});

  final DebtStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final overdue = context.moneyColors.overdue;

    return switch (status) {
      DebtStatus.open => _Badge(
        icon: Icons.schedule,
        label: l10n.debtOpen,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
      DebtStatus.overdue => _Badge(
        icon: Icons.warning_amber_outlined,
        label: l10n.debtOverdue,
        background: overdue.container,
        foreground: overdue.onContainer,
      ),
      DebtStatus.settled => _Badge(
        icon: Icons.check_circle_outline,
        label: l10n.debtSettled,
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
      ),
    };
  }
}
