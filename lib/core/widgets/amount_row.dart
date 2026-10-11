import 'package:flutter/material.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';
import 'package:money_scribe/core/theme/money_colors.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';

/// A tonal row: a soft icon circle, a title (and a note), and a signed amount
/// at the end in fixed-width figures. Income is green with a plus, spending is
/// red with a minus, so the meaning never rests on colour alone. With [onTap]
/// the row is a button and shows a small chevron.
class AmountRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.amount,
    this.subtitle,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Positive for income, negative for spending.
  final Money amount;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = amount.isNegative
        ? context.moneyColors.expense
        : context.moneyColors.income;

    return Semantics(
      button: onTap != null,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
              child: Row(
                children: [
                  IconCircle(
                    icon: icon,
                    size: 40,
                    background: money.container,
                    foreground: money.onContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.bodyLarge),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      context.moneyFormatter.formatSigned(amount),
                      style: theme.textTheme.titleMedium?.amount.copyWith(
                        color: money.color,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
