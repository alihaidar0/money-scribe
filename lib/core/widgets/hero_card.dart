import 'package:flutter/material.dart';
import 'package:money_scribe/core/theme/amount_text_style.dart';

/// A small figure under the main one of a [HeroCard].
class HeroDetail {
  const new({required this.label, required this.amount});

  final String label;

  /// The amount, already formatted.
  final String amount;
}

/// The card with the one figure a screen is about, such as the balance of the
/// month: navy with white text in light mode, `primaryContainer` in dark mode,
/// flat, with no gradient or decoration (`docs/DESIGN.md`, section 2.2).
class HeroCard extends StatelessWidget {
  const new({
    required this.label,
    required this.amount,
    this.details = const [],
    super.key,
  });

  final String label;

  /// The main amount, already formatted.
  final String amount;

  /// Smaller figures under it, such as income and spending.
  final List<HeroDetail> details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final background = isDark ? colors.primaryContainer : colors.primary;
    final foreground = isDark ? colors.onPrimaryContainer : colors.onPrimary;

    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: theme.textTheme.displaySmall?.amount.copyWith(
                  color: foreground,
                ),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    for (final detail in details)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${detail.label} '),
                            TextSpan(
                              text: detail.amount,
                              style: theme.textTheme.titleMedium?.amount
                                  .copyWith(color: foreground),
                            ),
                          ],
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: foreground,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
